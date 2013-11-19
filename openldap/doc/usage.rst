:Copyrights: Copyright (c) 2013, Hung Nguyen Viet

             All rights reserved.

             Redistribution and use in source and binary forms, with or without
             modification, are permitted provided that the following conditions
             are met:

             1. Redistributions of source code must retain the above copyright
             notice, this list of conditions and the following disclaimer.

             2. Redistributions in binary form must reproduce the above
             copyright notice, this list of conditions and the following
             disclaimer in the documentation and/or other materials provided
             with the distribution.

             THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
             "AS IS" AND ANY EXPRESS OR IMPLIED ARRANTIES, INCLUDING, BUT NOT
             LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
             FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
             COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
             INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES(INCLUDING,
             BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
             LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
             CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
             LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
             ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
             POSSIBILITY OF SUCH DAMAGE.
:Authors: - Hung Nguyen Viet

Usage
======

How to add an LDAP user entry?
------------------------------

This formula only creates LDAP users the first time it run (when install
slapd). List of users to create provided through pillar, see ``ldap:data``
in ``openldap/pillar.rst`` for more details.

To add more user entry after the first time formula run, any LDAP tool
can be used, includes:

- CLI: ``ldapadd`` from `ldap-utils` package that is installed by `openldap`
  state.
- The following GUI aren't yet available as salt states in `common` repository,
  but can be used if installed:
  - LAT http://sourceforge.net/p/ldap-at/wiki/Home/
  - Apache Directory Studio http://directory.apache.org/studio/
  - Web: phpLDAPAdmin http://phpldapadmin.sourceforge.net

For `ldapadd`, below example is how to create user ``testfoo`` entry. First
create an LPAD Data Interchange formated file
http://en.wikipedia.org/wiki/LDAP_Data_Interchange_Format with the expected
value, in this case ``testfoo.ldif``:

    dn: uid=testfoo,ou=people,dc=example,dc=com
    objectClass: inetOrgPerson
    cn: testfoo
    sn: testfoo
    uid: testfoo
    userPassword: testfoo
    mail: testfoo@example.com
    description: None

The password can be in clear text, or encrypted with ``slappasswd`` format.
``slappasswd`` is an utility that come in ``slapd`` package.

Such as::

    userPassword: {MD5}/+VTaU9QlkcVkDQ0MjWeAg==

Then load the file::

    # ldapadd -Y EXTERNAL -H ldapi:/// -f testfoo.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    adding new entry "uid=testfoo,ou=people,dc=example,dc=com"

A point to notice is `ldapadd` run as root and use -Y EXTERNAL for authenticate.
Normal (user/password) authenticate can be used for that, too.

Above example worked because entry ``ou=people,dc=example,dc=com`` is already
there (by our state - run ``ldapadd`` against the `usertree.ldif` file).

Content of `usertree.ldif` rendered from pillar, in this example is::

    ldap:
      usertree: openldap/usertree.ldif.jinja2
      log_level: 256
      suffix: dc=example,dc=com
      rootdn: cn=admin,dc=example,dc=com
      rootpw: '{MD5}/+VTaU9QlkcVkDQ0KjWeAg=='
      data:
        example.com:
          bob:
            cn: bob
            sn: bob
            passwd: bobpass
            desc:
            email: bob@example.com

How do email accounts created?
------------------------------

When used in conjunction with formula ``postfix`` and ``dovecot``.
If ``postfix`` is configured to serve virtual host
(set ``postfix:virtual_mailbox`` to ``True``),
OpenLDAP  will be used as authenticate backend, so, each LDAP entry which has
DN form ``uid=USERNAME,ou=people,dc=DOMAIN,dc=TLD`` will be used as an email
account.

Postfix need to maintain an alias database, that map LDAP entries to virtual
mailboxes. This is done by ``vmailbox`` in ``postfix`` formula, which is
rendered from ``ldap:data`` and will be applied each time ``ldap:data`` changed.

So, with above pillar, an email account is created named `bob@example.com`.

How to add email accounts after formula ran the fist time?
----------------------------------------------------------

Two thing need to be done:

- Add an LDAP entry in form: ``uid=USERNAME,ou=people,dc=DOMAIN,dc=TLD``
  See ``openldap/pillar.rst`` for more details about attributes of an user
  entry.
- Create a key in pillar likes already exist users to map recently created
  LDAP entry to a virtual mailbox. Run ``postfix`` formula again, to apply it.