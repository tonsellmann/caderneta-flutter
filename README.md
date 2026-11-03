# Caderneta

App de fiado para mercadinho, em Flutter. O dono anota a compra no balcão, o app diz quem está atrasado e quem cobrar primeiro, e a cobrança vai pelo WhatsApp com o Pix copia e cola já no valor da conta.

**Projeto conceito.** O Mercadinho Dois Irmãos e os clientes são fictícios.

- Demonstração: https://luisantoniodev.tech/projetos/caderneta-app/
- Portfólio: https://luisantoniodev.tech

## O problema

O fiado do mercadinho de bairro mora num caderno de capa dura atrás do balcão. Funciona para anotar, mas não responde às perguntas que importam:

- Quanto a loja tem para receber?
- Quem está atrasado, e desde quando?
- Quanto a Dona Cida deve, se ela pagou R$ 45,90 no mês passado e comprou mais três vezes depois?

Cobrar também é constrangedor. O dono manda áudio, o cliente pede "manda a chave Pix", o valor vai errado e a conta não fecha.

## O que o app faz

- **Anotar em dois toques.** O teclado grande do valor serve para anotar com o cliente esperando. A descrição é opcional.
- **A conta como no caderno.** O pagamento abate as compras mais antigas primeiro, e o que fica em aberto é sempre o mais recente. Lançamento errado não some: fica riscado, fora da conta, mas à vista.
- **Vencimento do jeito do bairro.** Quem tem dia do acerto (o dia do pagamento ou do benefício) paga nesse dia o que comprou no mês anterior. Quem não tem, paga em 30 dias.
- **Quem cobrar primeiro.** Os atrasados vêm na frente, do mais atrasado; depois quem tem conta aberta, do vencimento mais próximo; e quem não deve nada vai para o fim.
- **Limite.** Antes de anotar uma compra que passa do limite combinado, o app avisa quanto passa. Não bloqueia: quem decide é o dono.
- **Cobrança com Pix.** A mensagem lista o que está em aberto e traz o Pix copia e cola com o valor exato e um identificador do cliente, para a loja achar o pagamento no extrato. O QR Code aparece na tela, para o cliente que está no balcão.

## Por que Flutter

- **Um código, os aparelhos do balcão.** O dono do mercadinho usa Android de entrada; o filho que ajuda no caixa, iPhone; a contadora quer ver no computador. Flutter compila para os três a partir do mesmo código, e a demonstração do portfólio é o próprio app compilado para a web.
- **Desenha o que precisa.** A folha pautada com margem vermelha, a letra de mão nos lançamentos e o teclado próprio saem iguais em qualquer aparelho, sem depender dos componentes de cada sistema.
- **Funciona sem internet.** O caderno fica no aparelho. A internet só entra na hora de mandar a cobrança.

### O que ficou de fora

- **App nativo em Kotlin.** Atende o Android, mas o iPhone e o computador pediriam um segundo e um terceiro código.
- **React Native.** Também é um código só, mas a folha do caderno e o teclado dependeriam de mais bibliotecas, e a versão para o computador é menos madura.
- **Planilha ou app web.** Sem internet no balcão, não anota. E o mercadinho é exatamente o lugar onde o sinal cai.

## Decisões

- **Dinheiro em centavos inteiros.** R$ 23,50 é 2350. Conta de fiado não perde centavo em arredondamento.
- **O Pix segue o padrão do Banco Central** (BR Code, EMV), com o CRC-16 do manual. O teste confere o código gerado com o exemplo do próprio manual.
- **O WhatsApp abre com a mensagem pronta**, pelo link `wa.me`. Nada é enviado sem o dono apertar enviar.
- **O caderno fica no aparelho**, em JSON (`shared_preferences`). Um caderno de bairro tem centenas de clientes e alguns milhares de lançamentos, e isso cabe folgado.

## Como funciona

```
lib/
  dominio/       regras puras: conta, vencimento, ordem de cobrança, limite, Pix, mensagem
  dados/         o caderno no aparelho (JSON) e o caderno de exemplo
  estado/        o Caderno (ChangeNotifier): carrega, anota, risca e salva
  tela/          início, página do cliente, anotar, cobrar, novo cliente e o tema
test/            testes do domínio e das telas
fonts/           Plus Jakarta Sans e Caveat, com as licenças OFL
```

## Rodar

Precisa do Flutter 3.47 ou mais novo.

```bash
flutter pub get
flutter test
flutter run
```

Para a versão web, como a do portfólio:

```bash
flutter build web --release --base-href /demos/caderneta-app/
```

## Créditos

Fontes Plus Jakarta Sans (Tokotype) e Caveat (Impallari Type), SIL Open Font License 1.1, em `fonts/`.
