# http://phusion.github.io/baseimage-docker/
FROM phusion/baseimage

# To avoid any unnecessary warnings
ENV TERM=xterm-256color

# Where all the task's files live
ENV JOB_TASK_DIR=/job/task
ENV JOB_INPUTS_DIR=/job/inputs
ENV JOB_OUTPUTS_DIR=/job/outputs

# Use baseimage's init system.
CMD ["/sbin/my_init"]

# Install Herc.
ADD . $JOB_TASK_DIR
RUN add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) multiverse" && \
    add-apt-repository -y ppa:webupd8team/java && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections && \
    apt-get update && \
    apt-get install -y oracle-java7-installer && \

    # The following is needed for 'gsutil'
    apt-get install -y libffi-dev && \
    apt-get install -y libssl-dev && \
    apt-get install -y python-dev && \
    apt-get install -y python-pip && \
    pip install gsutil && \

    # Clean up intermediate files to keep the docker images small
    apt-get clean && \
    mkdir -p $JOB_INPUTS_DIR $JOB_OUTPUTS_DIR && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# These next 4 commands are for enabling SSH to the container.
# id_rsa.pub is referenced below, but this should be any public key
# that you want to be added to authorized_keys for the root user.
# Copy the public key into this directory because ADD cannot reference
# Files outside of this directory

#EXPOSE 22
#RUN rm -f /etc/service/sshd/down
#ADD id_rsa.pub /tmp/id_rsa.pub
#RUN cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
