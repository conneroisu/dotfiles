FROM opensuse/tumbleweed:latest

RUN mkdir /home/connerohnesorge/
RUN mkdir /home/connerohnesorge/dotfiles/
COPY . /home/connerohnesorge/dotfiles/
SHELL ["/bin/bash", "-c"]
RUN cd ./home/connerohnesorge/dotfiles && sh /home/connerohnesorge/scripts/install.sh


