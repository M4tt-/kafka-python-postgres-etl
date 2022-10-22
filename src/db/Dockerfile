FROM postgres
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD mysecretpassword
EXPOSE 5432
COPY config.db .
COPY init.sql /docker-entrypoint-initdb.d/