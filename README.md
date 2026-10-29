# maquinas

Gerenciamento das máquinas da sala do PET: acesso de fora da UFES, instalação e atualização em todas de uma vez, e o catálogo de configuração de cada uma.

## Como funciona

As máquinas ficam numa rede Tailscale do PET, ligada à organização `pet-eng-comp-org` do GitHub. Cada uma tem a conta `manutencao`, que só entra por chave SSH e só pelo Tailscale (o firewall recusa conexões vindas da rede do DI). O resto é feito pelo [Ansible](https://docs.ansible.com/) deste repositório.

| Arquivo | O que faz |
|---|---|
| `preparar.sh` | Roda uma vez em cada máquina nova, presencialmente. |
| `inventario.yml` | Lista das máquinas. |
| `base.yml` | Pacotes, chaves de acesso, atualização automática de segurança, firewall e Wake-on-LAN. |
| `atualizar.yml` | Atualiza tudo e reinicia só a máquina que precisa e que não tem ninguém usando. |
| `coleta.yml` | Lê a configuração de cada máquina e grava em `estado/`. |
| `chaves/` | Chaves SSH de quem administra. Tirar a chave daqui e rodar `base.yml` tira o acesso. |
| `politica.hujson` | Regras de acesso da rede Tailscale. |

## Máquina nova

1. Gerar uma chave de autenticação no painel do Tailscale, em Settings > Keys: de uso único, pré-aprovada e com a tag `tag:maquina`. De uso único porque ela fica no histórico do terminal da máquina, que outras pessoas usam.
2. Na máquina, com uma conta que tenha sudo:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/pet-eng-comp-org/maquinas/main/preparar.sh | sudo bash -s -- pet-<nome> <chave>
   ```
3. Pôr a máquina em `inventario.yml` e rodar `ansible-playbook base.yml --limit pet-<nome>`.
4. Na BIOS, ligar o Wake-on-LAN, se a máquina tiver.

## Uso

```sh
ansible-playbook coleta.yml                           # atualiza estado/ e estado/catalogo.csv
ansible-playbook atualizar.yml                        # atualiza todas
ansible pet-php -a "df -h /"                          # roda um comando numa
ssh pet-php                                           # entra numa
```

Para instalar um pacote em todas, pôr o nome na lista `pacotes` do `base.yml` e rodar o `base.yml`. Instalado direto pelo `ansible`, ele não fica em lugar nenhum e some da máquina que for reinstalada.

O `estado/catalogo.csv` tem as mesmas colunas do catálogo de computadores do Drive (Manutenção/Inventário).

Para administrar, a máquina de onde se roda o Ansible precisa estar na rede do PET, com a tag `tag:admin`, e ter a chave correspondente a uma das de `chaves/`.
