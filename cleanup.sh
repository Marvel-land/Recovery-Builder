#!/usr/bin/env bash

echo "::group::Disk Space Before Cleanup"
df -hlT /
echo "::endgroup::"

echo "::group::Clearing Docker Image Caches"
docker rmi -f $(docker images -q) &>/dev/null
echo "::endgroup::"

echo "::group::Uninstalling Unnecessary Applications"
sudo -EH apt-fast -qq -y update &>/dev/null
sudo -EH apt-fast -qq -y purge \
  ${APT_Pac4Purge} \
  clang-* clang-format-* libclang-common-*-dev libclang-cpp* libclang1-* \
  liblldb-* lld-* lldb-* llvm-*-dev llvm-*-runtime llvm-*-tools llvm-* \
  adoptopenjdk-* openjdk* ant* \
  *-icon-theme plymouth *-theme* fonts-* gsfonts gtk-update-icon-cache \
  google-cloud-sdk \
  apache2* nginx msodbcsql* mssql-tools mysql* libmysqlclient* unixodbc-dev postgresql* libpq-dev odbcinst* mongodb-* sphinxsearch \
  apport* popularity-contest \
  aspnetcore-* dotnet* \
  azure-cli session-manager-plugin \
  brltty byobu htop \
  buildah hhvm kubectl packagekit* podman podman-plugins skopeo \
  chromium-browser firebird* firefox google-chrome* xvfb \
  esl-erlang ghc-* groff-base rake r-base* r-cran-* r-doc-* r-recommended ruby* swig* \
  gfortran* \
  gh subversion mercurial mercurial-common \
  info install-info landscape-common \
  libpython2* imagemagick* libmagic* vim vim-* \
  man-db manpages \
  mono-* mono* libmono-* \
  nuget packages-microsoft-prod snapd yarn \
  php-* php5* php7* php8* snmp \
  &>/dev/null
sudo -EH apt-fast -qq -y autoremove &>/dev/null
echo "::endgroup::"

echo "::group::Disk Space After Cleanup"
df -hlT /
echo "::endgroup::"
