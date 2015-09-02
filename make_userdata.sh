#!/bin/bash -xe

cat <<EOF >userdata.sh
#!/bin/bash
date
set -x
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
release="\$(lsb_release -cs)"
if [ -n "${git_protocol}" ]; then
  export git_protocol="${git_protocol}"
fi
export no_proxy="127.0.0.1,169.254.169.254,localhost,consul,jiocloud.com"
echo no_proxy="'127.0.0.1,169.254.169.254,localhost,consul,jiocloud.com'" >> /etc/environment
if [ -n "${env_http_proxy}" ]
then
  export http_proxy=${env_http_proxy}
  echo http_proxy="'${env_http_proxy}'" >> /etc/environment
fi
if [ -n "${env_https_proxy}" ]
then
  export https_proxy=${env_https_proxy}
  echo https_proxy="'${env_https_proxy}'" >> /etc/environment
fi
wget -O puppet.deb -t 5 -T 30 http://apt.puppetlabs.com/puppetlabs-release-\${release}.deb
jiocloud_repo_deb_url=http://jiocloud.rustedhalo.com/ubuntu/jiocloud-apt-\${release}.deb
wget -O jiocloud.deb -t 5 -T 30 \${jiocloud_repo_deb_url}
dpkg -i puppet.deb jiocloud.deb
if no_proxy= wget -t 2 -T 30 -O internal.deb http://apt.internal.jiocloud.com/internal.deb
then
  dpkg -i internal.deb
fi
apt-get update
apt-get install -y puppet software-properties-common puppet-jiocloud jiocloud-ssl-certificate
if [ -n "${python_jiocloud_source_repo}" ]; then
  apt-get install -y python-pip python-jiocloud python-dev libffi-dev libssl-dev git
  pip install -e "${python_jiocloud_source_repo}@${python_jiocloud_source_branch}#egg=jiocloud"
fi
if [ -n "${puppet_modules_source_repo}" ]; then
  apt-get install -y git
  git clone ${puppet_modules_source_repo} /tmp/rjil
  if [ -n "${puppet_modules_source_branch}" ]; then
    pushd /tmp/rjil
    git checkout ${puppet_modules_source_branch}
    popd
  fi
  if [ -n "${pull_request_id}" ]; then
    pushd /tmp/rjil
    git fetch origin pull/${pull_request_id}/head:test_${pull_request_id}
    git config user.email "testuser@localhost.com"
    git config user.name "Test User"
    git merge -m 'Merging Pull Request' test_${pull_request_id}
    popd
  fi
  time gem install librarian-puppet-simple --no-ri --no-rdoc;
  mkdir -p /etc/puppet/manifests.overrides
  cp /tmp/rjil/site.pp /etc/puppet/manifests.overrides/
  mkdir -p /etc/puppet/hiera.overrides
  sed  -i "s/  :datadir: \/etc\/puppet\/hiera\/data/  :datadir: \/etc\/puppet\/hiera.overrides\/data/" /tmp/rjil/hiera/hiera.yaml
  cp /tmp/rjil/hiera/hiera.yaml /etc/puppet
  cp -Rvf /tmp/rjil/hiera/data /etc/puppet/hiera.overrides
  mkdir -p /etc/puppet/modules.overrides/rjil
  cp -Rvf /tmp/rjil/* /etc/puppet/modules.overrides/rjil/
  cp -av ./${env}.yaml /etc/puppet/hiera/data/env/
  if [ -n "${module_git_cache}" ]
  then
    cd /etc/puppet/modules.overrides
    wget -O cache.tar.gz "${module_git_cache}"
    tar xvzf cache.tar.gz
    time librarian-puppet update --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  else
    time librarian-puppet install --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  fi
  cat <<INISETTING | puppet apply
  ini_setting { basemodulepath: path => "/etc/puppet/puppet.conf", section => main, setting => basemodulepath, value => "/etc/puppet/modules.overrides:/etc/puppet/modules" }
  ini_setting { default_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => default_manifest, value => "/etc/puppet/manifests.overrides/site.pp" }
  ini_setting { disable_per_environment_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => disable_per_environment_manifest, value => "true" }
INISETTING
else
  puppet apply -e "ini_setting { default_manifest: path => \"/etc/puppet/puppet.conf\", section => main, setting => default_manifest, value => \"/etc/puppet/manifests/site.pp\" }"
fi
sudo mkdir -p /etc/facter/facts.d
echo 'consul_discovery_token='${consul_discovery_token} > /etc/facter/facts.d/consul.txt
echo 'current_version='${BUILD_NUMBER} > /etc/facter/facts.d/current_version.txt
echo 'env='${env} > /etc/facter/facts.d/env.txt
echo 'cloud_provider='${cloud_provider} > /etc/facter/facts.d/cloud_provider.txt

##
# Workaround to add the swap partition for baremetal systems, as even though
# cloudinit is creating the swap partition, its not added to the fstab and not
# enabled.
##
if [ -e /dev/disk/by-label/swap1 ] && [ `grep -cP '^LABEL=swap1[\s\t]+' /etc/fstab` -eq 0 ]; then
  echo 'LABEL=swap1 none swap sw 0 1' >> /etc/fstab
  swapon -a
fi
cp -av ./${env}.yaml /etc/puppet/hiera/data/env/
while true
do
  # first install all packages to make the build as fast as possible
  puppet apply --detailed-exitcodes \`puppet config print default_manifest\` --tags package
  ret_code_package=\$?
  # now perform base config
  (echo 'File<| title == "/etc/consul" |> { purge => false }'; echo 'include rjil::jiocloud' ) | puppet apply --detailed-exitcodes --debug
  ret_code_jio=\$?
  if [[ \$ret_code_jio = 1 || \$ret_code_jio = 4 || \$ret_code_jio = 6 || \$ret_code_package = 1 || \$ret_code_package = 4 || \$ret_code_package = 6 ]]
  then
    echo "Puppet failed. Will retry in 5 seconds"
    sleep 5
  else
    break
  fi
done
date
EOF
