#!/usr/bin/env bash
# Prepara uma máquina da sala do PET para ser gerenciada à distância.
# Roda uma vez só, na própria máquina:
#
#   curl -fsSL https://raw.githubusercontent.com/pet-eng-comp-org/maquinas/main/preparar.sh | sudo bash -s -- <nome> <chave-do-tailscale>
#
# Faz três coisas: dá o nome à máquina, cria a conta `manutencao` (só entra
# por chave SSH) e liga a máquina na rede Tailscale do PET. Daí em diante,
# todo o resto é feito pelo Ansible deste repositório.
set -euo pipefail

nome=${1:?uso: preparar.sh <nome> <chave-do-tailscale>}
chave_tailscale=${2:?uso: preparar.sh <nome> <chave-do-tailscale>}

[[ $EUID -eq 0 ]] || { echo "rode com sudo" >&2; exit 1; }

chaves_ssh=(
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkISheuM0ZE0YFCoEticLi3BPbd4O58jy34iBIotvyx manutencao@server"
)

echo "== nome: $nome"
hostnamectl set-hostname "$nome"
sed -i "s/^127\.0\.1\.1\s.*/127.0.1.1\t$nome/" /etc/hosts
grep -q "^127\.0\.1\.1" /etc/hosts || echo -e "127.0.1.1\t$nome" >> /etc/hosts

echo "== pacotes"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q openssh-server curl python3 sudo

echo "== conta manutencao"
id manutencao &>/dev/null || useradd --create-home --shell /bin/bash --comment "Manutenção do PET" manutencao
passwd --lock manutencao >/dev/null
install -d -m 700 -o manutencao -g manutencao ~manutencao/.ssh
printf '%s\n' "${chaves_ssh[@]}" > ~manutencao/.ssh/authorized_keys
chown manutencao:manutencao ~manutencao/.ssh/authorized_keys
chmod 600 ~manutencao/.ssh/authorized_keys
echo "manutencao ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/manutencao
chmod 440 /etc/sudoers.d/manutencao
visudo -cq

echo "== tailscale"
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
tailscale up --auth-key="$chave_tailscale" --hostname="$nome" --reset

echo
echo "Pronto: $nome está na rede do PET com o endereço $(tailscale ip -4)."
