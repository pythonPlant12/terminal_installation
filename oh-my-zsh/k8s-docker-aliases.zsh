# Kubernetes and Docker aliases and functions

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        return 1
    fi
    return 0
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Please install kubectl first."
        return 1
    fi
    return 0
}

# Docker aliases (with checks)
if command -v docker &> /dev/null; then
    alias dk='docker'
    
    # Docker container IP listing function
    dkpsip() {
        if ! check_docker; then return 1; fi
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | tail -n +2 | while read container_id container_name container_status; do
            if [[ $container_status == *"Up"* ]]; then
                ips=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$container_name" 2>/dev/null)
                echo "$container_id | $container_name | $ips"
            fi
        done
    }
else
    alias dk='echo "❌ Docker is not installed. Please install Docker first." && false'
    dkpsip() {
        echo "❌ Docker is not installed. Please install Docker first."
        return 1
    }
fi

# Kubernetes aliases (with checks)
if command -v kubectl &> /dev/null; then
    alias k='kubectl'
    
    # Additional useful kubectl aliases
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kgn='kubectl get nodes'
    alias kdp='kubectl describe pod'
    alias kds='kubectl describe service'
    alias kdd='kubectl describe deployment'
    alias kdn='kubectl describe node'
    alias klf='kubectl logs -f'
    alias kex='kubectl exec -it'
else
    alias k='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgp='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgs='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgd='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgn='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdp='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kds='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdd='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdn='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias klf='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kex='echo "❌ kubectl is not installed. Please install kubectl first." && false'
fi

# kubectx and kubens aliases (with checks)
if command -v kubectx &> /dev/null; then
    alias kc='kubectx'
else
    alias kc='echo "❌ kubectx is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

if command -v kubens &> /dev/null; then
    alias kn='kubens'
else
    alias kn='echo "❌ kubens is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

# k9s alias (with check)
if command -v k9s &> /dev/null; then
    alias k9='k9s'
else
    alias k9='echo "❌ k9s is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

# Helm alias (with check)
if command -v helm &> /dev/null; then
    alias h='helm'
    alias hls='helm list'
    alias hin='helm install'
    alias hun='helm uninstall'
    alias hup='helm upgrade'
else
    alias h='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hls='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hin='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hun='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hup='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi
