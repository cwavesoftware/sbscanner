FROM ubuntu:20.04

# Install required tools for faraday download
RUN apt update && apt install -y git python3-pip libpq-dev python3-dev

# Clone faraday git repository
WORKDIR /root
RUN mkdir faraday
COPY ./ /root/faraday/

# Install the server's python dependencies
WORKDIR /root/faraday
RUN git clone https://github.com/cwavesoftware/faraday_angular_frontend.git faraday/frontend
RUN pip install .
RUN apt install -y python2

COPY ./Docker/faraday-server/run-faraday-server.py /root/run-faraday-server.py

RUN echo alias python=python3 >> /root/.profile
RUN mkdir -p /root/.faraday/config && mkdir -p /root/.faraday/logs
RUN touch /root/.faraday/config/server.ini
RUN pip install itsdangerous==1.1.0


CMD python2 /root/run-faraday-server.py \
    --faraday-root /root/faraday/faraday \
    --faraday-data /root/.faraday \
    --pg-user $PGSQL_USER \
    --pg-pass $PGSQL_PASSWD \
    --pg-db $PGSQL_DBNAME \
    --pg-host $PGSQL_HOST \
    --su-mail $FARADAY_SUPERUSER_EMAIL \
    --su-name $FARADAY_SUPERUSER_NAME \
    --su-pass $FARADAY_SUPERUSER_PASSWORD