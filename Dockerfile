FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive 
# installing requirements. we install redis-server only for redis-cli
RUN apt update && apt install -y python3 python3-pip git make gcc redis-server jq curl
RUN curl -OL https://golang.org/dl/go1.21.6.linux-amd64.tar.gz
RUN tar -C /usr/local -xvf go1.21.6.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version
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
ENV GOROOT /usr/local/go
ENV PATH=$PATH:$GOPATH/bin
ENV GO111MODULE=on
RUN go install -v github.com/projectdiscovery/notify/cmd/notify@latest

RUN apt install -y libpcap-dev nmap
RUN mkdir sbscanner
COPY scripts/* notify-config.yaml /root/sbscanner/

WORKDIR /root/sbscanner
ENTRYPOINT [ "bash", "sbscanner.sh" ]
