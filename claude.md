metadata:
  document: claude.md
  format: yaml
  version: 1
  last_updated: 2026-03-08
  next_review_due: 2026-04-08
  related_context_files:
    agent_entrypoint: AGENTS.md
    agent_entrypoint_purpose: concise operational guidance for coding agents
    operations_runbook: RUNBOOK.md
    operations_runbook_purpose: step-by-step procedures and incident recovery
    tests_guide: tests/TESTS.md
    tests_guide_purpose: canonical verification checks for documentation and operations
    architecture_reference: claude.md
    architecture_reference_purpose: detailed cluster architecture and decisions
  freshness_policy:
    review_cadence: monthly
    also_review_when:
      - cluster topology changes
      - runtime components change
      - operating model decisions move from pending to decided
  status_snapshot:
    operational_runbook: scaffold_created
    verification_suite: baseline_created
    secrets_strategy: pending
    image_registry_solution: pending
    backup_strategy: not_implemented
    tls_strategy: pending

project:
  name: K3s-RaspberryPi
  description: >
    Repository for provisioning and managing a K3s Kubernetes cluster
    on Raspberry Pi edge hardware.
  scope:
    provisions:
      - edge clusters running on lightweight hardware (k3s)
    does_not_include:
      - application source code
      - application containers
      - application Helm charts
  known_application_repositories:
    - name: edge-monitor-app
      description: >
        Primary edge monitoring application repository. Contains source code,
        Dockerfile, and Helm chart for deployment to the k3s cluster.

edge_cluster:
  primary_node:
    hostname: pi-1.local
    connection:
      ssh_target: pi-1.local
    hardware:
      platform: Raspberry Pi
      version: 5
      architecture: arm64
    role: >
      Primary edge compute node running a single-node k3s Kubernetes cluster.
      Intended for lightweight workloads that run close to the network boundary.
  topology:
    current: single-node
    node_naming_convention: pi-{n}.local
    reasoning: >
      The cluster is currently single-node (pi-1.local). The numbered naming
      convention is intentional to support future expansion to multi-node
      clusters without renaming existing nodes.
    future_nodes:
      - additional worker nodes or a second cluster are planned
      - roles for future nodes (worker, storage, etc.) are TBD
  network_exposure:
    scope: LAN only
    public_access: false
    reasoning: >
      The cluster is intentionally not exposed to the public internet.
      All services are accessible only from the local WiFi network.

design_principles:
  minimalism: >
    Edge clusters should remain lightweight and simple.
    Avoid unnecessary operators or heavy platform layers.
  reproducibility: >
    The entire cluster should be reproducible from this repository.
  independence: >
    The cluster should operate independently of external cloud
    services whenever possible.
  reliability: >
    The system must recover automatically after node reboot
    without manual intervention.

architecture:
  separation_of_concerns:
    infra_repository:
      owns:
        - k3s cluster provisioning
        - node bootstrap
        - namespace creation
        - cluster networking
        - ingress controllers
        - cluster observability
        - secrets scaffolding
        - cluster lifecycle operations
    application_repositories:
      own:
        - application source code
        - Dockerfiles
        - multi-architecture container builds
        - Helm charts
        - service configuration
        - application Kubernetes manifests
  helm_strategy:
    location: application repositories
    reasoning: >
      Deployment configuration should live with the application code
      so that releases, configuration, and infrastructure evolve together.
  infra_repo_does_not_contain:
    - application Helm charts
    - application manifests

ingress:
  controller: Traefik
  distribution_default: true
  reasoning: >
    Traefik is the default ingress controller bundled with k3s.
    No replacement is planned.
  tls:
    status: not yet configured
    decision: pending
    last_reviewed: 2026-03-08

secrets:
  status: not yet decided
  last_reviewed: 2026-03-08
  requirements:
    - must be GitOps friendly
    - secrets should be safely storable or referenceable in git
    - solution must work in a single-node k3s environment
  candidates_to_evaluate:
    - Sealed Secrets
    - External Secrets Operator
    - SOPS + age/gpg
  decision: pending

image_registry:
  type: self-hosted
  location: local network
  multi_arch: true
  reasoning: >
    A self-hosted registry avoids reliance on external services,
    keeps image pulls fast on the LAN, and supports arm64 images.
  solution: TBD
  last_reviewed: 2026-03-08

runtimes:
  k3s:
    type: kubernetes
    distribution: k3s
    environment: edge-runtime
    architecture: arm64
    host:
      ssh_target: pi-1.local
    hardware:
      target_platform: raspberry-pi
    purpose: >
      Lightweight Kubernetes runtime designed for edge workloads
      running on constrained hardware.
    system_requirements:
      swap_disabled: true
      container_runtime: containerd
      persistent_storage: local-path
      auto_restart_on_reboot: true
    storage:
      current: local-path provisioner
      future: >
        A network storage solution such as NFS or Longhorn
        may be introduced later.
    networking:
      scope: LAN only
      tolerate_intermittent_connectivity: true
      prefer_local_processing: true
      public_exposure: false
    persistence_strategy:
      current:
        storage: local-path
      philosophy: >
        The cluster should tolerate node reboot without
        requiring manual intervention.
      backup_strategy:
        status: not yet implemented
        last_reviewed: 2026-03-08
    resource_constraints:
      philosophy: >
        Edge workloads must remain lightweight to avoid
        exhausting Raspberry Pi CPU or memory resources.
      recommendations:
        - prefer single replica deployments
        - avoid high memory workloads
        - use resource limits
  components:
    api_server:
      purpose: Kubernetes control plane API endpoint used by kubectl.
    scheduler:
      purpose: Assigns pods to nodes based on available resources.
    controller_manager:
      purpose: Maintains desired cluster state.
    containerd:
      purpose: Container runtime used by k3s.
    kubelet:
      purpose: Node agent responsible for running containers.
    flannel:
      purpose: Lightweight overlay network for pod communication.
    core_dns:
      purpose: Cluster DNS resolution for services.

raspberry_pi_requirements:
  kernel_configuration:
    description: >
      Kubernetes requires specific Linux kernel features to be enabled.
      Raspberry Pi OS must be configured to expose these features.
    required_settings:
      - enable cgroup memory support
      - enable cgroup CPU accounting
      - enable overlay filesystem
      - enable br_netfilter module
  recommended_cmdline:
    file: /boot/cmdline.txt
    parameters:
      - cgroup_enable=cpuset
      - cgroup_enable=memory
      - cgroup_memory=1
  cgroups_configuration:
    description: >
      Kubernetes relies on Linux control groups to manage CPU and memory
      resources for containers.
    requirements:
      - cgroup memory accounting enabled
      - systemd cgroup driver compatibility
      - containerd configured for systemd cgroups
    verification_commands:
      - mount | grep cgroup
      - cat /proc/cgroups
      - kubectl describe node

build_and_images:
  development_architecture:
    local_machine: apple-silicon-m4
    architecture: arm64
  deployment_architecture:
    raspberry_pi: arm64
  multi_arch_strategy:
    strategy: docker-buildx
    supported_platforms:
      - linux/amd64
      - linux/arm64
    requirements:
      - multi-arch images for all services
      - single Dockerfile per service
      - immutable image tags
      - avoid architecture-specific base images
      - prefer distroless or alpine arm64-compatible images
      - test images on both architectures when possible
      - build once, deploy anywhere

makefile:
  purpose: Operational commands for managing the k3s edge cluster.
  targets:
    k3s-install: Install k3s on the edge node via SSH.
    k3s-start: Start k3s services.
    k3s-stop: Stop the k3s cluster.
    kubeconfig-sync: Retrieve kubeconfig for local kubectl usage.

how_to_operate_repo:
  status: placeholder
  last_updated: 2026-03-08
  intent: >
    This section is intentionally a placeholder while operational workflows are
    being designed and validated.
  build_plan:
    - define required local prerequisites and versions
    - define bootstrap flow from a clean Raspberry Pi host
    - define day-2 operations (start, stop, upgrade, recover)
    - define validation checks after each operation
    - define rollback and break-glass procedures
  acceptance_criteria_for_completion:
    - a new operator can reproduce cluster setup from docs only
    - operations include expected output and failure troubleshooting
    - runbook commands are copy/paste-safe

verification:
  strategy: command_first
  source_of_truth: tests/TESTS.md
  default_command: ./tests/run-all.sh
  cluster_command: RUN_CLUSTER_TESTS=1 ./tests/run-all.sh
  required_for_change_types:
    docs_or_context_changes:
      run:
        - ./tests/run-all.sh
    operational_or_cluster_changes:
      run:
        - ./tests/run-all.sh
        - RUN_CLUSTER_TESTS=1 ./tests/run-all.sh
  test_scripts:
    - tests/01_context_integrity.sh
    - tests/02_docs_consistency.sh
    - tests/03_freshness_policy.sh
    - tests/10_cluster_smoke.sh

observability:
  cluster_level:
    managed_by: infra repository
    stack:
      - prometheus
      - grafana
    runtime: kubernetes
    purpose: Provide cluster-level monitoring for nodes and infrastructure.
  application_level:
    managed_by: application repositories
    requirements:
      - readiness probes
      - liveness probes
      - stdout logging
      - optional metrics endpoints

deployment_philosophy:
  build_once: true
  helm_with_application_code: true
  infra_manages_cluster_only: true
  isolate_apps_by_namespace: true
  arm64_support_required: true
  survive_reboot_without_manual_intervention: true
  lan_only_no_public_exposure: true
  gitops_friendly_secrets: true

future_roadmap:
  - multi-node edge clusters
  - automated node bootstrap
  - centralized cluster observability
  - remote cluster reporting
  - persistent metrics storage
  - secrets management solution
  - self-hosted image registry
  - network-attached storage solution
