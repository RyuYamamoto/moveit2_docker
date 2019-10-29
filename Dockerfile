FROM osrf/ros:dashing-desktop

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN curl -sSL http://get.gazebosim.org | sh

RUN apt update && apt install -y \
ros-dashing-action-msgs \
ros-dashing-message-filters \
ros-dashing-yaml-cpp-vendor \
ros-dashing-urdf \
ros-dashing-rttest \
ros-dashing-tf2 \
ros-dashing-tf2-geometry-msgs \
ros-dashing-rclcpp-action \
ros-dashing-cv-bridge \
ros-dashing-image-transport \
ros-dashing-camera-info-manager
RUN apt install -y ros-dashing-rmw-opensplice-cpp
RUN apt install -y \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-pip \
  python-rosdep \
  python3-vcstool \
  python3-sip-dev \
  python3-numpy \
  wget
RUN apt update && apt install -y \
ros-dashing-rttest \
ros-dashing-rclcpp-action \
ros-dashing-gazebo-dev \
ros-dashing-gazebo-msgs \
ros-dashing-gazebo-plugins \
ros-dashing-gazebo-ros \
ros-dashing-gazebo-ros-pkgs

RUN pip3 install tensorflow

# Additional utilities
RUN pip3 install transforms3d billiard psutil

# Fast-RTPS dependencies
RUN apt install --no-install-recommends -y \
  libasio-dev \
  libtinyxml2-dev

RUN mkdir -p ~/ros2_mara_ws/src
WORKDIR /root/ros2_mara_ws
RUN wget https://raw.githubusercontent.com/AcutronicRobotics/MARA/dashing/mara-ros2.repos
RUN vcs import src < mara-ros2.repos
RUN wget https://raw.githubusercontent.com/AcutronicRobotics/gym-gazebo2/dashing/provision/additional-repos.repos
RUN vcs import src < additional-repos.repos
RUN cd src/gazebo_ros_pkgs && git checkout dashing
# Avoid compiling erroneus package
RUN touch ~/ros2_mara_ws/src/orocos_kinematics_dynamics/orocos_kinematics_dynamics/COLCON_IGNORE
RUN cd ~/ros2_mara_ws/src/HRIM && pip3 install hrim && hrim generate models/actuator/servo/servo.xml && hrim generate models/actuator/gripper/gripper.xml
RUN mkdir -p ~/ros2_mara_ws/src && \
    cd ~/ros2_mara_ws/src && \
    git clone https://github.com/AcutronicRobotics/moveit2 -b master && \
    cd .. && \
    vcs import src < src/moveit2/moveit2.repos && \
    export ROS_DISTRO=dashing && \
    rosdep update && rosdep install -q -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO}
RUN bash -c "source /opt/ros/dashing/setup.bash && cd ~/ros2_mara_ws && colcon build --merge-install --packages-skip individual_trajectories_bridge && touch ~/ros2_mara_ws/install/share/orocos_kdl/local_setup.sh ~/ros2_mara_ws/install/share/orocos_kdl/local_setup.bash"
RUN cd ~ && git clone -b dashing https://github.com/AcutronicRobotics/gym-gazebo2
RUN cd ~/gym-gazebo2 && pip3 install -e .
RUN cd ~  && \
    git clone https://github.com/openai/gym && \
    cd gym && \
    pip3 install -e .
RUN cd ~/gym-gazebo2 && \
    echo "source `pwd`/provision/mara_setup.sh" >> ~/.bashrc && \
    bash -c "source ~/.bashrc"
RUN echo "source /opt/ros/dashing/setup.bash" >> ~/.bashrc && \
    echo "source ~/ros2_mara_ws/install/setup.bash" >> ~/.bashrc && \
    echo " source /usr/share/gazebo-9/setup.sh" >> ~/.bashrc && \
    echo "export PYTHONPATH=$PYTHONPATH:~/ros2_mara_ws/install/lib/python3/dist-packages" >> ~/.bashrc && \
    echo "export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:~/ros2_mara_ws/src/MARA" >> ~/.bashrc && \
    echo "export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:~/ros2_mara_ws/src/MARA/mara_gazebo_plugins/build/" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_opensplice_cpp" >> ~/.bashrc && \
    bash -c "source ~/.bashrc"

# My settins.
RUN apt install -y tmux
RUN cd ~ && git clone https://github.com/RyuYamamoto/haze_setting
RUN cp ~/haze_setting/tmux/tmux.conf ~/.tmux.conf
