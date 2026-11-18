.PHONY: help install-collections install check syntax lint reset-rootpw \
        vault-encrypt vault-decrypt vault-edit vault-view

INVENTORY  := inventory.yml
PLAYBOOK   := install_openldap.yml
COLLECTION := collections/requirements.yml
SECRETS    := vars/secrets.yml

# Sous WSL, /mnt/c est « world writable » : Ansible y ignore le ansible.cfg du
# répertoire courant (et donc vault_password_file). Un chemin explicite est pris en compte.
export ANSIBLE_CONFIG := $(CURDIR)/ansible.cfg

help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  install-collections   ansible-galaxy : installe les collections requises"
	@echo "  syntax                vérifie la syntaxe du playbook"
	@echo "  check                 exécution en dry-run (--check)"
	@echo "  install               déploie OpenLDAP sur ldap_servers"
	@echo "  reset-rootpw          réinitialise le mot de passe root LDAP"
	@echo "  lint                  ansible-lint sur le playbook"
	@echo ""
	@echo "Vault :"
	@echo "  vault-encrypt         chiffre vars/secrets.yml"
	@echo "  vault-decrypt         déchiffre vars/secrets.yml"
	@echo "  vault-edit            édite vars/secrets.yml chiffré"
	@echo "  vault-view            affiche vars/secrets.yml chiffré"
	@echo ""

# ─── COLLECTIONS ─────────────────────────────────────────────────────────────

install-collections:
	ansible-galaxy collection install -r $(COLLECTION)

# ─── VALIDATION ──────────────────────────────────────────────────────────────

syntax:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --syntax-check

lint:
	ansible-lint $(PLAYBOOK)

# ─── DÉPLOIEMENT ─────────────────────────────────────────────────────────────

check:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff

install:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

reset-rootpw:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags reset-rootpw

# ─── VAULT ───────────────────────────────────────────────────────────────────

vault-encrypt:
	ansible-vault encrypt $(SECRETS)

vault-decrypt:
	ansible-vault decrypt $(SECRETS)

vault-edit:
	ansible-vault edit $(SECRETS)

vault-view:
	ansible-vault view $(SECRETS)
