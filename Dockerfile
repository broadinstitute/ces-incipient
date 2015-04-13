# http://phusion.github.io/baseimage-docker/
FROM phusion/baseimage

# To avoid any unnecessary warnings
ENV TERM xterm-256color

# Aurora sandbox location
ENV SANDBOX_DIR /mnt/mesos/sandbox/sandbox
ENV JOB_SYMLINK_DIR $SANDBOX_DIR/__jobio

# Where all the task's files live
ENV JOB_ROOT_DIR /job
ENV JOB_TASK_DIR $JOB_ROOT_DIR/task
ENV JOB_INPUTS_DIR $JOB_ROOT_DIR/inputs
ENV JOB_OUTPUTS_DIR $JOB_ROOT_DIR/outputs

# Use baseimage's init system.
CMD ["/sbin/my_init"]

# Install Herc.
RUN add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) multiverse" && \
    add-apt-repository -y ppa:webupd8team/java && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections && \
    apt-get update && \
    apt-get install -y r-base && \
    apt-get install -y tabix && \
    apt-get install -y oracle-java7-installer && \
    apt-get install -y aria2 && \
    apt-get install -y python3-requests && \

    # The following is needed for 'gsutil'
    apt-get install -y libffi-dev && \
    apt-get install -y libssl-dev && \
    apt-get install -y python-dev && \
    apt-get install -y python-pip && \
    pip install gsutil && \

    # Clean up intermediate files to keep the docker images small
    apt-get clean && \
    mkdir -p $JOB_SYMLINK_DIR && \
    ln -s $JOB_SYMLINK_DIR $JOB_ROOT_DIR && \
    mkdir -p $JOB_INPUTS_DIR $JOB_OUTPUTS_DIR && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . $JOB_TASK_DIR

# These next 4 commands are for enabling SSH to the container.
# id_rsa.pub is referenced below, but this should be any public key
# that you want to be added to authorized_keys for the root user.
# Copy the public key into this directory because ADD cannot reference
# Files outside of this directory

#EXPOSE 22
#RUN rm -f /etc/service/sshd/down
#ADD id_rsa.pub /tmp/id_rsa.pub
#RUN cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
