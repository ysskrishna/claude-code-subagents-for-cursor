# Retry plan

We retry failed requests up to three times. The delay doubles each time, starting at 200 ms.

Requests that fail with a 4xx error are not retried, because a retry will not fix them. Only network erors and 5xx responses are retried.

The retry settings live in `config/retry.yaml`. Teh limit can be changed per service.
