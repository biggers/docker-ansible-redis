# -*-sh-*-
# ansible-redis/Dockerfile
#
# VERSION    13.10
#
# REFs: 
#   http://www.ansible.com/blog/2014/02/12/installing-and-building-docker-with-ansible
#   https://github.com/wrale/docker-dna
#   https://index.docker.io/u/cohesiveft/haproxy-ssl-ssh/
#   http://docs.docker.io/en/latest/examples/running_redis_service/ 
#   https://github.com/phusion/baseimage-docker
FROM phusion/baseimage:0.9.8
MAINTAINER biggers@utsl.com

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# -------- Put your own build instructions here --------

RUN mkdir -p /root/.ssh
ADD ./authorized_keys_dotssh  /root/.ssh/authorized_keys

# Ensure correct permissions for root/.ssh
RUN  chmod 700 /root/.ssh \
  && chmod 600 /root/.ssh/authorized_keys \
  && chown -R root /root/.ssh

# Need some "base" packages, for Ansible
ADD ./apt_mirrors_list /etc/apt/sources.list 
RUN apt-get update
RUN apt-get install -y git python-software-properties software-properties-common

# Install the "latest" packaged Ansible
RUN  add-apt-repository -y ppa:rquillo/ansible \
  && apt-get update \
  && apt-get install -y ansible

# Run the Ansible playbook
RUN git clone https://github.com/biggers/ansible-redis.git /var/tmp/ansible-redis
ADD hosts /etc/ansible/hosts
WORKDIR /var/tmp/ansible-redis
RUN ansible-playbook ./site.yml -c local

EXPOSE  22 6379

# -------- Put your own build instructions here --------

# ---- boot-time scripts, in /etc/init.d

RUN mkdir -p /etc/my_init.d
ADD logtime.sh  /etc/my_init.d/logtime.sh
# ADD ansible-run-boot.sh  /etc/my_init.d/ansible-run-boot.sh

# ---- boot-time scripts, in /etc/init.d

RUN mkdir -p /var/run

# Redis DB service, via 'runit'
RUN mkdir -p /var/redis
ADD runit_run/redis.conf.in /etc/redis.conf

RUN mkdir -p /etc/service/redis
ADD runit_run/redis_run.sh /etc/service/redis/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# EXAMPLE "docker run":
#
#   JOB=$(sudo docker run -d -p 22 -p 6379 -t ansible-redis:2.5 /sbin/my_init)
#
#   sudo docker ps -a
#   ssh -vp NNNNN root@127.0.0.1
