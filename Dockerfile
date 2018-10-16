FROM debian:stretch

# Superset version
ARG SUPERSET_VERSION=0.27.0

# Configure environment
ENV GUNICORN_BIND=0.0.0.0:8088 \
    GUNICORN_LIMIT_REQUEST_FIELD_SIZE=0 \
    GUNICORN_LIMIT_REQUEST_LINE=0 \
    GUNICORN_TIMEOUT=60 \
    GUNICORN_WORKERS=2 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=apache/incubator-superset \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset
ENV GUNICORN_CMD_ARGS="--workers ${GUNICORN_WORKERS} --timeout ${GUNICORN_TIMEOUT} --bind ${GUNICORN_BIND} --limit-request-line ${GUNICORN_LIMIT_REQUEST_LINE} --limit-request-field_size ${GUNICORN_LIMIT_REQUEST_FIELD_SIZE}"

# Create superset user & install dependencies
RUN useradd -U -m superset && \
    mkdir /etc/superset  && \
    mkdir ${SUPERSET_HOME} &&\
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    echo "deb http://ftp.cn.debian.org/debian/ stretch main" > /etc/apt/sources.list && \
    echo "deb http://ftp.cn.debian.org/debian/ stretch-updates main" >> /etc/apt/sources.list && \
    echo "deb http://ftp.cn.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        default-libmysqlclient-dev \
        freetds-dev \
        freetds-bin \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        python3-dev \
        python3-pip && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/* && \
    mkdir -p ~/.pip/ && \
    echo "[global]" >> ~/.pip/pip.conf && \
    echo "timeout = 6000" >> ~/.pip/pip.conf && \
    echo "index-url = https://mirrors.ustc.edu.cn/pypi/web/simple" >> ~/.pip/pip.conf && \
    echo "trusted-host = mirrors.ustc.edu.cn" >> ~/.pip/pip.conf && \
    curl https://raw.githubusercontent.com/apache/incubator-superset/master/requirements.txt -o requirements.txt && \
    sed -i '/tabulator==1.15.0/d' requirements.txt && \
    sed -i 's/markdown==3.0/markdown==2.6.11/g' requirements.txt && \
    pip3 install --no-cache-dir -r requirements.txt && \
    rm requirements.txt

RUN pip3 install --no-cache-dir \
        Werkzeug==0.12.1 \
        flask-cors==3.0.3 \
        flask-mail==0.9.1 \
        flask-oauth==0.12 \
        flask_oauthlib==0.9.3 \
        gevent==1.2.2 \
        impyla==0.14.0 \
        infi.clickhouse-orm==1.0.2 \
        mysqlclient==1.3.7 \
        psycopg2==2.6.1 \
        pyathena==1.2.5 \
        pyhive==0.5.1 \
        pyldap==2.4.28 \
        pymssql==2.1.3 \
        redis==2.10.5 \
        sqlalchemy-clickhouse==0.1.5.post0 \
        sqlalchemy-redshift==0.5.0 

RUN pip3 install --no-cache-dir -i https://pypi.org/simple \
        tabulator==1.15.0 

RUN pip3 install --no-cache-dir \
        superset==${SUPERSET_VERSION} && \
    chown -R superset:superset /usr/local/lib/python3.5/dist-packages

# Configure Filesystem
COPY superset /usr/local/bin
VOLUME /home/superset \
       /etc/superset \
       /var/lib/superset
WORKDIR /home/superset

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
CMD ["gunicorn", "superset:app"]
USER superset
