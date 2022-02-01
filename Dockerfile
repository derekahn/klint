FROM golang:1.17.6-alpine3.15 AS builder

ENV PACKAGES="\
  kubectl \
  helm \
  "

RUN apk add \
  --no-cache \
  --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
  --allow-untrusted \
  $PACKAGES

RUN go install github.com/controlplaneio/kubesec/v2@latest \
  && mkdir /user \
  && echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd \
  && echo 'nobody:x:65534:' > /user/group

FROM alpine:3.15

WORKDIR /src

COPY --from=builder /user/group /user/passwd /etc/

COPY --chown=nobody --from=builder /usr/bin/kubectl /usr/bin/kubectl
COPY --chown=nobody --from=builder /usr/bin/helm /usr/bin/helm
COPY --chown=nobody --from=builder /go/bin/kubesec /usr/bin/kubesec

COPY --chown=nobody --from=k8s.gcr.io/kustomize/kustomize:v3.8.7 /app/kustomize /usr/bin/kustomize
COPY --chown=nobody --from=garethr/kubeval:0.15.0 /kubeval /usr/bin/kubeval
COPY --chown=nobody --from=zegl/kube-score:v1.13.0 /kube-score /usr/bin/kube-score

USER nobody:nobody

CMD ["/bin/sh"]
