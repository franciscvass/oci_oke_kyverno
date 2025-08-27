prometheus:
  service:
    type: LoadBalancer
  prometheusSpec:
    additionalScrapeConfigs: 
    - job_name: gpu-metrics
      scrape_interval: 1s
      metrics_path: /metrics
      scheme: http
      static_configs:
        - targets: ["${vm_to_monitor1}","${vm_to_monitor2}"]
