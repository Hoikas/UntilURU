#    Copyright (C) 2021  Adam Johnson
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM debian:latest AS pls_debootstrap

# The Plasma Servers are all very old and linked against ancient versions of glibc and MySQL.
# So, we need to assemble a rather old Linux distribution to form the basline of our work.
# We'll use Debian Sarge.
RUN apt-get update && apt-get install -y debootstrap && \
    debootstrap \
        --arch i386 \
        --exclude=exim4,exim4-base,exim4-config,exim4-daemon-lite,gcc-3.3-base \
        sarge /usr/src \
        http://archive.debian.org/debian/
RUN rm -rf /usr/src/{dev,proc} && \
    mkdir -p /usr/src/{dev,proc} && \
    mkdir -p /usr/src/etc && \
    cp /etc/resolv.conf /usr/src/etc/

# This is the base layer that every Until URU container will run in. It *should* be a minimal
# install of Debian Sarge.
FROM scratch AS pls_base
COPY --from=pls_debootstrap /usr/src/ /
RUN apt-get update

# These are some default values for the database schtuff, so we don't have to keep
# copying and pasting the same crap over and over again in docker-compose.yml
ENV DB_ADDRESS=db
ENV DB_PORT=3306
ENV DB_USERNAME=plasma
ENV DB_PASSWORD=MySuperSecretPassword

# This container should only be used for debugging.
FROM pls_base AS pls_interactive
CMD "/bin/bash"

# Database container
FROM pls_base AS pls_mysql
RUN apt-get install -y mysql-client mysql-server
COPY ["database/entrypoint.sh", "database/manage.sh", "/usr/src/"]
RUN ln -s /usr/src/manage.sh /usr/local/bin/manage_uu
ENTRYPOINT ["/usr/src/entrypoint.sh"]

# Uru server container
FROM pls_base AS pls_uru_builder
COPY plasma/servers /usr/src

# Extract the Plasma Servers--note that a separate patch was released by chip for the
# auth server due to a bug preventing the Vault Manager from working, so we need to
# do it separately.
WORKDIR /usr/src
RUN apt-get install -y bzip2
RUN ./plServers-0.38.10.run --noexec --target plServers
RUN mkdir -p /opt/plServers/var /opt/plServers/etc /opt/plServers/VaultBlobs /opt/plServers/SavedGames
RUN mv plServers/bin/Linux/x86/bin /opt/plServers && mv plServers/share /opt/plServers
RUN tar -jxf plNetAuthServer-0.38.10-p1.tar.bz2
# plNetAuthServer contacts the so-called CGAS (Cyan Global Auth Server), which has been defunct
# for over 14 years at this point. On the plus side, if we null out the URI in the binary,
# it will revert to using the MySQL database for authentication.
RUN \
    sed -e "s,http://auth.plasma.corelands.com/info,\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00," \
        plNetAuthServer-0.38.10-p1/Linux/plNetAuthServer > /opt/plServers/bin/plNetAuthServer

# Uru runtime
FROM pls_base AS pls_uru_server
RUN apt-get install -y curl mysql-client
COPY --from=pls_uru_builder /opt/plServers /opt/plServers
COPY ["plasma/entrypoint.sh", "/opt/plServers/"]
RUN \
    useradd plasma && \
    chown -R plasma /opt/plServers

USER plasma
WORKDIR /opt/plServers
ENTRYPOINT ["/opt/plServers/entrypoint.sh"]
