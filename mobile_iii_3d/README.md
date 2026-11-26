# MOBILE-III 3D

Aplicativo Flutter com login local SQLite e autenticação social pelo Firebase.

## Executar

```bash
flutter pub get
flutter run -d chrome
```

Usuário local de demonstração:

- Email: `admin@teste.com`
- Senha: `123456`

## Configuração dos provedores sociais

No Firebase Console, habilite **Authentication > Sign-in method**:

1. Google
2. GitHub
3. Apple

Para Web, registre os domínios autorizados em **Authentication > Settings > Authorized domains**.

Para Android, confirme que `android/app/google-services.json` corresponde ao projeto Firebase configurado e adicione a impressão SHA-1/SHA-256 do certificado em **Project settings > Your apps > Android**.

Após alterar provedores ou configurações do Firebase:

```bash
flutterfire configure
flutter pub get
flutter run
```
