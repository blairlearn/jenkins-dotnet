##########################################################
### Dockerfile for Jenkins-builds of NCI dotnet core applications

FROM jenkins

USER root

# Work around https://github.com/dotnet/cli/issues/1582 until Docker releases a
# fix (https://github.com/docker/docker/issues/20818). This workaround allows
# the container to be run with the default seccomp Docker settings by avoiding
# the restart_syscall made by LTTng which causes a failed assertion.
ENV LTTNG_UST_REGISTER_TIMEOUT 0

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libcurl3 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu52 \
        liblttng-ust0 \
        libssl1.0.0 \
        libstdc++6 \
        libunwind8 \
        libuuid1 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 1.0.0-preview2-003131
ENV DOTNET_SDK_DOWNLOAD_URL https://dotnetcli.blob.core.windows.net/dotnet/preview/Binaries/$DOTNET_SDK_VERSION/dotnet-dev-debian-x64.$DOTNET_SDK_VERSION.tar.gz

RUN curl -SL $DOTNET_SDK_DOWNLOAD_URL --output dotnet.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch

# Install the github-release tool.
ENV RELEASE_TOOL_URL https://github.com/aktau/github-release/releases/download/v0.6.2/linux-amd64-github-release.tar.bz2 
RUN curl -SL $RELEASE_TOOL_URL --output /tmp/github-release.tar.bz2 \
    && mkdir -p /usr/share/github-release \
    && tar -jxf /tmp/github-release.tar.bz2 -C /tmp \
    && cp /tmp/bin/linux/amd64/github-release /usr/share/github-release/github-release \
    && ln -s /usr/share/github-release/github-release /usr/bin/github-release \
    && rm /tmp/github-release.tar.bz2 \
    && rm -rf /tmp/bin

user jenkins
