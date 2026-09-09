FROM debian:bookworm-slim

# cadabra2 for derivation grading, numpy/sympy for everything else.
# libgmpxx4ldbl is a genuine missing dependency of the cadabra2 package --
# without it `import cadabra2` dies on libgmpxx.so.4.
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      cadabra2 \
      python3 \
      python3-numpy \
      python3-sympy \
      python3-gmpy2 \
      libgmpxx4ldbl \
      libgmp10 \
 && rm -rf /var/lib/apt/lists/*

# Submissions run as this user, which owns nothing and can write nowhere
# except /tmp. Defence in depth: the container is the real boundary.
RUN useradd --create-home --shell /usr/sbin/nologin grader

WORKDIR /srv
COPY app.py runner.py ./
COPY problems ./problems

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
EXPOSE 8080
USER grader
CMD ["python3", "app.py"]
