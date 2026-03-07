# datacenter-openldap-playbooks

Playbooks Ansible pour le déploiement et la gestion du serveur OpenLDAP via la collection `nsfabrice2009.config`.

---

## Structure

```
datacenter-openldap-playbooks/
├── Makefile                        # Cibles de déploiement et gestion
├── ansible.cfg
├── collections/
│   └── requirements.yml            # Collections requises
├── install_openldap.yml            # Playbook unique de déploiement
├── inventory.yml                   # Inventaire du serveur
└── vars/
    ├── variables.yml               # Variables du déploiement
    └── secrets.yml                 # Secrets (à chiffrer avec Vault)
```

---

## Prérequis

Installer les collections requises :

```bash
make install-collections
# ou
ansible-galaxy collection install -r collections/requirements.yml
```

---

## Utilisation via Makefile

```bash
make help               # Afficher les cibles disponibles
make syntax             # Vérifier la syntaxe du playbook
make check              # Dry-run (--check --diff)
make install            # Déployer OpenLDAP
make reset-rootpw       # Réinitialiser le mot de passe root LDAP
make lint               # Lancer ansible-lint
```

---

## Configuration

### Variables principales (`vars/variables.yml`)

| Variable          | Valeur                        | Description                        |
|-------------------|-------------------------------|------------------------------------|
| `ldap_basedn`     | `dc=devsecops,dc=lan`         | Base DN de l'annuaire              |
| `ldap_bind_dn`    | `dc=devsecops,dc=lan`         | DN de connexion (rootDN)           |
| `ldap_server_uri` | `ldap://192.168.1.119:389`    | URI du serveur LDAP                |

### Utilisateurs (`vars/variables.yml`)

| Utilisateur          | Groupes                          |
|----------------------|----------------------------------|
| `fabrice.ngatcheu`   | `devops`, `middleware`, `usilo`  |

### Secrets (`vars/secrets.yml`)

| Variable                              | Description                          |
|---------------------------------------|--------------------------------------|
| `ldap_bind_pw`                        | Mot de passe du rootDN               |
| `vault_openldap_server_rootpw`        | Mot de passe root OpenLDAP           |
| `vault_user_fabrice_ngatcheu_password`| Mot de passe utilisateur             |

---

## Réinitialisation du mot de passe root

Le playbook découvre automatiquement le DN de la base de données via `cn=config` et applique le nouveau mot de passe via SASL EXTERNAL (sans credentials) :

```bash
make reset-rootpw
```

Le playbook :
1. Recherche dynamiquement le DN de la base (`olcSuffix=dc=devsecops,dc=lan`)
2. Génère le hash SSHA via `slappasswd`
3. Applique via `ldapmodify -Y EXTERNAL -H ldapi:///`
4. Vérifie la connexion avec le nouveau mot de passe

---

## Chiffrement des secrets

```bash
# Chiffrer
ansible-vault encrypt vars/secrets.yml

# Modifier
ansible-vault edit vars/secrets.yml

# Déchiffrer
ansible-vault decrypt vars/secrets.yml
```

Pour déployer avec le vault chiffré :

```bash
ansible-playbook -i inventory.yml install_openldap.yml --ask-vault-pass
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

### 2. Tester la connexion admin

```bash
ldapsearch -x -H ldap://192.168.1.119:389 \
  -D "dc=devsecops,dc=lan" \
  -w '<mot_de_passe>' \
  -b "dc=devsecops,dc=lan" -s base
```

### 3. Lister tous les utilisateurs

```bash
ldapsearch -x -H ldap://192.168.1.119:389 \
  -D "dc=devsecops,dc=lan" -w '<mot_de_passe>' \
  -b "dc=devsecops,dc=lan" "(objectClass=inetOrgPerson)" cn mail
```

### 4. Lister les groupes

```bash
ldapsearch -x -H ldap://192.168.1.119:389 \
  -D "dc=devsecops,dc=lan" -w '<mot_de_passe>' \
  -b "dc=devsecops,dc=lan" "(objectClass=groupOfUniqueNames)"
```

### 5. Tester l'authentification d'un utilisateur

```bash
ldapwhoami -x -H ldap://192.168.1.119:389 \
  -D "uid=fabrice.ngatcheu,ou=people,dc=devsecops,dc=lan" \
  -w '<mot_de_passe_utilisateur>'
```

Résultat attendu :
```
dn:uid=fabrice.ngatcheu,ou=people,dc=devsecops,dc=lan
```

### 6. Vérifier les bases cn=config

```bash
ansible ldap_servers -i inventory.yml -m shell \
  -a "ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config '(objectClass=olcDatabaseConfig)' dn 2>/dev/null"
```

---

## Connexion via VSCode LDAP Explorer

| Champ          | Valeur                     |
|----------------|----------------------------|
| Host           | `ldap://192.168.1.119:389` |
| Bind DN        | `dc=devsecops,dc=lan`      |
| Bind Password  | *(voir `ldap_bind_pw`)*    |
| Base DN        | `dc=devsecops,dc=lan`      |
