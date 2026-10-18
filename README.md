# 🌸 PlantCare

## Sobre o projeto

O PlantCare é um projeto desenvolvido em Flutter e Dart para a matéria do curso técnico. A ideia é criar um aplicativo em que cada usuário possa cadastrar suas plantas e ter as informações delas salvas, sem precisar anotar tudo separadamente.

Além disso, o aplicativo conta com login, perfil e uma área para consultar o histórico de cuidados.

## O que dá para fazer no aplicativo?

- Criar uma conta e fazer login.
- Cadastrar plantas com suas informações.
- Visualizar as plantas cadastradas.
- Excluir plantas.
- Consultar o histórico de cuidados.
- Acessar o perfil do usuário.

Os dados são armazenados usando os serviços do Firebase, para que as informações possam continuar disponíveis quando o aplicativo for aberto novamente.

## Tecnologias usadas

Escolhi o Flutter e o Dart para desenvolver o aplicativo. Para a parte de cadastro de usuários, utilizo o Firebase Authentication, e para salvar os dados, o Cloud Firestore.

Também usei Git e GitHub para organizar o código e acompanhar as mudanças feitas no projeto. O manual foi desenvolvido com HTML e CSS.

## Como executar

Para rodar o PlantCare no computador, é necessário ter o Flutter instalado e configurado, além do VS Code e do Google Chrome.

Primeiro, abra a pasta do projeto no terminal e instale as dependências:

```bash
flutter pub get
```

Depois, execute o aplicativo no Chrome:

```bash
flutter run -d chrome
```

Se quiser verificar se há problemas no código, use:

```bash
flutter analyze
```

Para executar o projeto em outro computador, também é necessário ter acesso à configuração do Firebase utilizada pelo aplicativo.

## Como o projeto está organizado

Os arquivos foram separados de acordo com suas funções, para facilitar a organização e as alterações no código.

- `lib/main.dart`: inicia o aplicativo.
- `lib/models/plant.dart`: contém o modelo utilizado para representar uma planta.
- `lib/services/historico_service.dart`: reúne operações relacionadas ao histórico.
- `lib/screens/`: contém as telas de login, cadastro, início, plantas, histórico, perfil e navegação principal.
- `manual/`: contém os arquivos do manual técnico.
- `pubspec.yaml`: contém as dependências do Flutter.

## Banco de dados

O PlantCare utiliza o Firebase para autenticação e armazenamento das informações.

No Firestore, os dados são organizados por usuário. Cada conta possui suas próprias coleções de plantas e histórico, de acordo com a estrutura configurada no projeto.

As regras de segurança do banco controlam quem pode consultar e modificar esses dados.

## Manual do projeto

O manual técnico fica dentro da pasta `manual`. Para abrir, basta acessar o arquivo `index.html` pelo navegador.

Nele estão as informações sobre a instalação, a organização dos arquivos e o funcionamento do aplicativo.

## Informações do trabalho

- **Nome:** PlantCare
- **Desenvolvedora:** Michelle Rickli da Silva 
- **Curso:** INFORMÁTICA
- **Turma:** 2 INFO B


---