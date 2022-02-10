FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive 
# installing requirements. we install redis-server only for redis-cli
RUN apt update && apt install -y python3 python3-pip git make gcc redis-server golang-go jq
# installing masscan
WORKDIR /root
RUN git clone https://github.com/robertdavidgraham/masscan
WORKDIR /root/masscan
RUN make && make install
# installing faraday-cli
WORKDIR /root
RUN pip install faraday-cli
# installing notify
ENV GOPATH /root/go
ENV PATH=$PATH:$GOPATH/bin
ENV GO111MODULE=on
RUN go get -v github.com/projectdiscovery/notify/cmd/notify@latest

RUN mkdir sbscanner
COPY scripts/* notify-config.yaml /root/sbscanner/

RUN apt install -y libpcap-dev

# installing nmap
RUN apt install -y nmap

WORKDIR /root/sbscanner
ENTRYPOINT [ "bash", "sbscanner.sh" ]
