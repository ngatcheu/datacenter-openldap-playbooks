# datacenter-openldap-playbooks

Playbooks Ansible pour le déploiement du serveur OpenLDAP via la collection `nsfabrice2009.config`.

---

## Structure

```
datacenter-openldap-playbooks/
├── ansible.cfg
├── collections/
│   └── requirements.yml        # Collections requises
├── install_openldap.yml        # Playbook unique de déploiement
├── inventory.yml               # Inventaire du serveur
└── vars/
    ├── variables.yaml          # Variables du déploiement
    └── secrets.yaml            # Secrets (à chiffrer avec Vault)
```

---

## Prérequis

Installer les collections requises :

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

---

## Utilisation

### Déployer le serveur OpenLDAP

```bash
ansible-playbook -i inventory.yml install_openldap.yml --ask-vault-pass
```

---

## Chiffrement des secrets

```bash
# Chiffrer
ansible-vault encrypt vars/secrets.yaml

# Modifier
ansible-vault edit vars/secrets.yaml

# Déchiffrer
ansible-vault decrypt vars/secrets.yaml
```

---

## Rôle utilisé

| Playbook | Rôle | Description |
|---|---|---|
| `install_openldap.yml` | `nsfabrice2009.config.openldap_ansible_role` | Installe et configure le serveur OpenLDAP (`slapd`) |

---

## Tests après déploiement

### 1. Vérifier que slapd tourne

```bash
ansible ldap_servers -i inventory.yml -m shell -a "systemctl status slapd --no-pager"
```

### 2. Lister tous les utilisateurs

```bash
ansible ldap_servers -i inventory.yml -m shell \
  -a "ldapsearch -x -H ldap://localhost -b 'dc=devsecops,dc=lan' '(objectClass=inetOrgPerson)' cn mail"
```

### 3. Lister les groupes et leurs membres

```bash
ansible ldap_servers -i inventory.yml -m shell \
  -a "ldapsearch -x -H ldap://localhost -b 'ou=groups,dc=devsecops,dc=lan' '(objectClass=groupOfUniqueNames)'"
```

### 4. Tester l'authentification d'un utilisateur

```bash
ansible ldap_servers -i inventory.yml -m shell \
  -a "ldapwhoami -x -H ldap://localhost -D 'uid=fabrice.ngatcheu,ou=people,dc=devsecops,dc=lan' -w 'MOT_DE_PASSE'"
```

Résultat attendu :
```
dn:uid=fabrice.ngatcheu,ou=people,dc=devsecops,dc=lan
```

### 5. Vérifier les bases de données cn=config

```bash
ansible ldap_servers -i inventory.yml -m shell \
  -a "ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config '(objectClass=olcDatabaseConfig)' dn 2>/dev/null"
```
