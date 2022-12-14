create or alter procedure REGISTRAPAGAMENTO (
    IN_IDPK bigint,
    IN_Z001DATETIME timestamp,
    IN_Z002INDICEPAG integer,
    IN_Z003VLDIGITADO numeric(15,2))
returns (
    ID integer,
    IDPK bigint,
    Z001DATETIME timestamp,
    Z002INDICEPAG integer,
    Z003VLDIGITADO numeric(15,2),
    Z004VLREGISTRADO numeric(15,2),
    Z005DESCPAG varchar(60),
    Z006INDICESAT smallint,
    ZRESTANTE numeric(15,2),
    ZTROCO numeric(15,2))
as
declare variable LINDICEPAGAMENTO integer;
declare variable LIDPKEMPRESA bigint;
declare variable LFDESC varchar(60);
declare variable LFINDICESAT smallint;
declare variable LFEMITEDOCFIS smallint;
declare variable SLINEBREAK char(23);
declare variable LCNPJ varchar(17);
declare variable LXNOME varchar(60);
declare variable LXFANT varchar(60);
declare variable LXLGR varchar(60);
declare variable LIDVENDA type of column IDE.ID;
declare variable LW16VNF type of column WTOTAL.W16VNF;
declare variable LB005SIT type of column IDE.B005SIT;
declare variable LVLPAGO numeric(15,2);
declare variable LIDEID type of column IDE.ID;
declare variable LIDEB001DATETIME type of column IDE.B001DATETIME;
declare variable LIDEB002NATOP type of column IDE.B002NATOP;
declare variable LIDEB003NROPDV type of column IDE.B003NROPDV;
declare variable LIDEB004OPERADOR type of column IDE.B004OPERADOR;
declare variable LIDEB005SIT type of column IDE.B005SIT;
declare variable LIDEB006IDMOVCAIXA type of column IDE.B006IDMOVCAIXA;
declare variable LIDEB007IDSESSAO type of column IDE.B007IDSESSAO;
declare variable LIDEB008VOLUME type of column IDE.B008VOLUME;
declare variable LSUMCX003VTOTALVENDASBRUTA type of column CX003.VTOTALVENDASBRUTA;
declare variable LWTOTALCX003W03VBC type of column WTOTAL.W03VBC;
declare variable LWTOTALCX003W04VICMS type of column WTOTAL.W04VICMS;
declare variable LWTOTALCX003W04AVICMSDESON type of column WTOTAL.W04AVICMSDESON;
declare variable LWTOTALCX003W05VBCST type of column WTOTAL.W05VBCST;
declare variable LWTOTALCX003W06VST type of column WTOTAL.W06VST;
declare variable LWTOTALCX003W07VPROD type of column WTOTAL.W07VPROD;
declare variable LWTOTALCX003W08VFRETE type of column WTOTAL.W08VFRETE;
declare variable LWTOTALCX003W09VSEG type of column WTOTAL.W09VSEG;
declare variable LWTOTALCX003W10VDESC type of column WTOTAL.W10VDESC;
declare variable LWTOTALCX003W11VII type of column WTOTAL.W11VII;
declare variable LWTOTALCX003W12VIPI type of column WTOTAL.W12VIPI;
declare variable LWTOTALCX003W13VPIS type of column WTOTAL.W13VPIS;
declare variable LWTOTALCX003W14VCOFINS type of column WTOTAL.W14VCOFINS;
declare variable LWTOTALCX003W15VOUTRO type of column WTOTAL.W15VOUTRO;
declare variable LWTOTALCX003W16VNF type of column WTOTAL.W16VNF;
declare variable LWTOTALCX003W16AVTOTTRIB type of column WTOTAL.W16AVTOTTRIB;
declare variable LWTOTALCX003W17AVTROCO type of column WTOTAL.W17AVTROCO;
BEGIN
 SLINEBREAK  = ''||ASCII_CHAR(13) || ASCII_CHAR(10)||'';
 LVLPAGO = 0.00;

  IF ( :IN_IDPK IS NULL OR ( :IN_IDPK  <=  0 ) ) THEN
  EXCEPTION EEBADPARAM 'O VALOR IN_IDPK , ID DA VENDA NAO FOI INFORMADO! '
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_IDPK '
    ||' um valor nao foi informado, impossivel de filtrar por 0 ou vazio'
    ||:SLINEBREAK||' PARAMETRO :IN_IDPK ESTA NULL OU VALOR INVALIDO ! ';

  IF ( :IN_Z003VLDIGITADO IS NULL OR ( :IN_Z003VLDIGITADO  <=  0 ) ) THEN
  EXCEPTION EEBADPARAM 'O VALOR IN_Z003VLDIGITADO , VALOR DIGITADO NAO '
    || 'FOI INFORMADO OU INFORMADO INCORRETAMENTE! '
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_Z003VLDIGITADO '
    ||' um valor nao foi informado, impossivel de registar um valor null ou zero'
    ||:SLINEBREAK||' PARAMETRO :IN_Z003VLDIGITADO ESTA NULL OU VALOR INVALIDO ! ';


  IF ( :IN_Z002INDICEPAG IS NULL OR ( :IN_Z002INDICEPAG  <=  0 ) ) THEN
  EXCEPTION EEBADPARAM 'O VALOR ID , IN_INDICE DO PAGAMENTO NAO FOI INFORMADO! '
    ||:SLINEBREAK||'Esse erro e: O parametro :Z002INDICEPAG '
    ||' um valor nao foi informado, impossivel de filtrar por 0 ou vazio'
    ||:SLINEBREAK||' PARAMETRO :IN_Z002INDICEPAG ESTA NULL OU VALOR INVALIDO ! ';

 /***************************************************************************
  * CARREGA AS FORMAS DE PAGAMENTO CAASTRADAS NO SISTEMA
  *
 ***************************************************************************/
 SELECT

  COALESCE(FF.ID,-1),
    FF.IDPKEMPRESA,
    FF.FDESC,
    FF.FINDICESAT,
    FF.FEMITEDOCFIS

 FROM FINALIZADORAS FF
   WHERE FF.ID = :IN_Z002INDICEPAG
   INTO  :LINDICEPAGAMENTO,
         :LIDPKEMPRESA,
         :LFDESC,
         :LFINDICESAT,
         :LFEMITEDOCFIS;

  /***************************************************************************
  * VERIFICA E VALIDA , SE N??O HOUVER NENHUMA FORMA DE PAGAMENTO CADASTRADA
  * NA TABELA O SISTEMA NAO VAI PROSSEGUIR
  *
 ***************************************************************************/

 IF ( COALESCE(LINDICEPAGAMENTO,-1) <= 0 ) THEN
  EXCEPTION EECRITICALFAIL 'NAO EXISTEM FORMAS DE PAGAMENTOS CADASTRADAS NO SISTEMA! '
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_Z002INDICEPAG '
    ||' um valor foi informado, mas nao existe uma forma de pagamento cadastrada! '
    ||:SLINEBREAK||'TABELA FINALIZADORAS ESTA VAZIA ! ';

 /***************************************************************************
  * RECUPERA INFORMA????ES DA TABELA IDE EMIT E WTOTAL
  * PARA USO NAS VALIDA????ES E ISER????ES
  *
 ***************************************************************************/

  SELECT 
    COALESCE(II.ID,-1),
    EE.CNPJ,
    EE.XNOME,
    EE.XFANT,
    EE.XLGR,
    WW.W16VNF,
    II.B005SIT
 FROM IDE II
  LEFT JOIN EMIT   EE ON ( EE.IDPK = II.ID )
  LEFT JOIN WTOTAL WW ON ( WW.IDPK = II.ID )
  WHERE II.ID = :IN_IDPK

  INTO :LIDVENDA,
       :LCNPJ,
       :LXNOME,
       :LXFANT,
       :LXLGR,
       :LW16VNF,
       :LB005SIT;

  /***************************************************************************
  *IF ( COALESCE(:LIDVENDA,-1) <= 0 ) THEN
  *
  * VERIFICA E VALIDA , SE N??O HOUVER NENHUMA VENDA OU O VALOR DO ID RECUPEADO
  * FOR -1 OU NULL , O COALESCE AJUSTA O NULL||-1
  * O SISTEMA ENTENDERA QUE NAO EXISTE UMA VENDA NA TABELA IDE PARA
  * EFETUAR UMA TRANSA????O DE PAGAMENTO
  *
  * IF ( :LB005SIT  <> 0 ) THEN
  *
  * NA SEGUNDA VALIDACAO
  * SE A SITUACAO DA VENDA ESTIVER  DIFERENTE DE 0: ABERTA , ENTENDE-SE QUE
  * A VENDA NAO PODE RECEBER TRANSA????ES DE PAGAMENTOS
  *
  *
  *
  *
 ***************************************************************************/

   IF ( COALESCE(:LIDVENDA,-1) <= 0 ) THEN
  EXCEPTION EECRITICALFAIL 'NAO EXISTE UMA VENDA REGISTRADA COM O NUMERO '||:IN_IDPK
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_IDPK '
    ||' um valor foi informado, mas nao existe uma venda com o valor informado| '
    ||:SLINEBREAK||'SEM VENDA REGISTRADA PARA O ID INFORMADO! ';

 IF ( :LB005SIT  <> 0 ) THEN
     EXCEPTION EECRITICALFAIL 'VENDA DE NUMERO '||:IN_IDPK
    ||' NAO PODE SER MOVIMENTADA , '
    ||'informe uma venda valida( Aberta ) para registrar uma forma de pagamento'
    ||:SLINEBREAK||'Esse erro e: O parametro :in_IDPK esta '
    ||'associado a uma venda na tabela IDE com Status diferente de 0 ABERTA '
    ||:SLINEBREAK||' REGISTRO COM SITACAO DIFERENTE DE 0 ';


/***************************************************************************
  *
  * RECUPERA E SOMA TODO OS VALORES DA TABELA ZPAG
  * PARA QUE SE RECUPERE E ARMAZENE TODOS OS VALORES JA EFETUADOS
  *
  *  IF ( :LVLPAGO  >= :LW16VNF ) THEN
  *  SE O VALOR PAGO FOR MAIOR OU IGUAL AO VALOR DO TOTAL DA VNF OU TOTAL DA
  * VENDA OU DA OCORRENCIA FISCAL , ENTENDE-SE QUE TUDO FOI PAGO
  *
 ***************************************************************************/
  SELECT COALESCE(SUM(ZZ.Z004VLREGISTRADO),0.00)
   FROM ZPAG ZZ WHERE ZZ.IDPK = :IN_IDPK
   INTO :LVLPAGO;

  IF ( COALESCE(:LVLPAGO,0.00)  >= :LW16VNF ) THEN
     EXCEPTION EECRITICALFAIL 'VENDA DE NUMERO '||:IN_IDPK
    ||' JA TEVE TODO SEU VALOR REGISTRADO, '
    ||'A venda informada, teve seu valor total ja registrado.'
    ||:SLINEBREAK||'Esse erro e: O parametro :in_IDPK esta  '
    ||'associado a uma venda na tabela IDE ja paga '
    ||:SLINEBREAK||' REGISTRO BLOQUEADO | PAGAMENTO COMPLETO ';


 /***************************************************************************
  *
  * COME??A TODOS OS PROCESSOS DE CALCULOS
  *
  *  IF ( :IN_Z003VLDIGITADO >=  :ZRESTANTE ) THEN
  *  SE O VALOR DIGITADO FOR MAIOR QUE O RESTANTE
  *  RESTANTE JA INICIA COM O ( TOTAL PAGO RECUPERADO - VALOR TOTAL DA VNF )
  *  SE FOR
  *   ENTENDE-SE QUE ESTOU TRANSACIONANDO TODO O VALOR INFORMADO
  *   O VALOR DA TRANSACAO OU MAIS (  SE FOR MAIS GERAR TROCO )
  *
 ***************************************************************************/

 ZTROCO = 0.00;
 ZRESTANTE = ( :LW16VNF - :LVLPAGO );

 IF ( :IN_Z003VLDIGITADO >=  :ZRESTANTE ) THEN
  BEGIN
    LVLPAGO          = ( :IN_Z003VLDIGITADO - :ZRESTANTE );
    ZTROCO           = ( :IN_Z003VLDIGITADO -  :ZRESTANTE );
    Z004VLREGISTRADO =  :ZRESTANTE;
    ZRESTANTE        = 0.00;
  END ELSE
  BEGIN
     LVLPAGO          = :IN_Z003VLDIGITADO;
     ZRESTANTE        = ( :ZRESTANTE - :IN_Z003VLDIGITADO );
     Z004VLREGISTRADO = :IN_Z003VLDIGITADO;
  END


  /***************************************************************************
  * APOS O CALCULO
  * REGISTRAR O PAGAMENTO DA VENDA
  *
 ***************************************************************************/

 INSERT INTO ZPAG (IDPK, Z001DATETIME, Z002INDICEPAG, Z003VLDIGITADO,
                   Z004VLREGISTRADO, Z005DESCPAG, Z006INDICESAT)

  VALUES (
          :IN_IDPK,
          :IN_Z001DATETIME,
          :IN_Z002INDICEPAG,
          :IN_Z003VLDIGITADO,
          :Z004VLREGISTRADO,
          :LFDESC,
          :LFINDICESAT )

  RETURNING ID,
            IDPK,
            Z001DATETIME,
            Z002INDICEPAG,
            Z003VLDIGITADO,
            Z004VLREGISTRADO,
            Z005DESCPAG,
            Z006INDICESAT
  INTO :ID,
       :IDPK,
       :Z001DATETIME,
       :Z002INDICEPAG,
       :Z003VLDIGITADO,
       :Z004VLREGISTRADO,
       :Z005DESCPAG,
       :Z006INDICESAT;

 /***************************************************************************
  * APOS A TRANSA????O OCORRER
  * VERIFICAR SE TEM TROCO SE TIVER TROCO
  * GRAVAR NA TABELA WTOTAL O TROCO DA VENDA
 ***************************************************************************/
  IF (:ZTROCO > 0.00 ) THEN
    UPDATE WTOTAL SET W17AVTROCO = :ZTROCO
    WHERE (WTOTAL.IDPK = :IDPK);

 SUSPEND;

 /***************************************************************************
  * APOS A TRANSA????O OCORRER
  * VERIFICAR SE TUDO FOI PAGO, SE HOUVE O PAGAMENTO TOTAL
  * DA VENDA, MODIFICAR O STATUS DA VENDA NA TABELA IDE PARA 1 = FECHADA
 ***************************************************************************/

 SELECT
  COALESCE(SUM(ZZ.Z004VLREGISTRADO),0.00)
   FROM ZPAG ZZ WHERE ZZ.IDPK = :IN_IDPK  INTO :LVLPAGO;

  IF ( :LVLPAGO  >= :LW16VNF ) THEN
 BEGIN
   UPDATE IDE SET B005SIT = 1 WHERE (IDE.ID = :IDPK);

 /***************************************************************************
  * APOS A TRANSA????O OCORRER
  * COME??AR A GRAVAR OS VALORES DE SESS??O DO CAIXA
  * AO FECHAR UMA VENDA IREMOS ENTAO ATUALIZAR AS POSICOES
  * DE CAIXA DO LIVRO DE MOVIMENTO DE CAIXA
  * RECUPERAR O ID DO CAIXA E ID DE SESS??O DA TABELA IDE
  * RECUPERAR OS VALORES DO CAIXA ATUAIS
  *
  *
 ***************************************************************************/

  SELECT IDE.ID,
         IDE.B002NATOP,
         IDE.B003NROPDV,
         IDE.B004OPERADOR,
         IDE.B005SIT,
         IDE.B006IDMOVCAIXA,
         IDE.B007IDSESSAO,
         IDE.B008VOLUME,
         COALESCE(WTOTAL.W07VPROD,0.00)
  FROM IDE
   JOIN WTOTAL ON ( WTOTAL.IDPK = IDE.ID )
   WHERE IDE.ID = :IN_IDPK
    INTO
         :LIDEID,
         :LIDEB002NATOP,
         :LIDEB003NROPDV,
         :LIDEB004OPERADOR,
         :LIDEB005SIT,
         :LIDEB006IDMOVCAIXA,
         :LIDEB007IDSESSAO,
         :LIDEB008VOLUME,
         :LWTOTALCX003W07VPROD;

   /* NO DETALHAMENTO E EXTRATO DE CAIXA A VENDA BRUTA ?? O VALOR TOTAL DE PRODUTOS E
   * SERVI??OS SEM DESCONTOS E ACRESCIMOS NO TOTALIZADOR
   *
   */
  EXECUTE PROCEDURE ATTCAIXA_OPVENDA( :LIDEB007IDSESSAO,:LWTOTALCX003W07VPROD, :IN_IDPK );


 END


END^

SET TERM ; ^

COMMENT ON PROCEDURE REGISTRAPAGAMENTO IS
' PROGRAMA FRENTE PDV VERSAO 3.0

 CRIACAO:
        24/ 10/ 2022

 REVISAO:
      26/10/2022

 MODULO:
        REGISTRA O PAGAMENTO DA VENDA

 ANALISTA:
         CARLOS ALBERTO DIAS DA SILVA F.


 PARAMETROS:
        IN_IDPK BIGINT  /*INFORMAR O ID DA VENDA*/
        IN_Z001DATETIME  /* INFORMAR A DATA E HORA NO FORMATO SQL TIME STAPMP */
        IN_Z002INDICEPAG INTEGER  /* INFORMAR O INDICE DA FINALIZADORA DE PAGAMENTO O ID */
        IN_Z003VLDIGITADO NUMERIC(15,2) /* INFORMAR O VALOR DIGITADO NA OPERACAO */

  OBJETIVO:
        REGISTRA A FORMA DE PAGAMENTO DA VENDA, O SISTEMA VAI TRANSACIONAR
        RECUPERANDO OS VALORES DA TABELA IDE, WTOTAL,
        EMITE,ZPAG, PROD, FINALIZADORAS

        SE FAZ NECESSARIO O CADASTRO DAS FORMAS DE PAGAMENTOS NA TABELA
        FINALIZADORA , O SISTEMA ACIONA UMA PROCEDURE PARA ATUALIZAR OS
        DADOS TOTALIZADORES DA SESS??O DO CAIXA NA TABELA CX003

  PASSOS:
        [ 1 ] VALIDA OS PARAMETROS DE ENTRADA VALRES NECESS??RIOS PARA QUE SE
              CUMPRA O PROCEDIMENTO.
              DEVE DEVOLVER EXPLICITAMENTE UMA EXCEPTION TIPADA PARA
              IDENDIFICACAO E FACIL COMPREENSAO.

        [ 2 ] CARREGA AS FORMAS DE PAGAMENTOS CADASTRADAS , UMA TABELA
              COM TODAS AS CONFIGURACOES DAS FORMAS QUE PODEM SEREM UTILIZADAS
              PARA PAGAMENTOS.

        [ 3 ] SE NAO HOUVER UMA FORMA DE PAGAMENTO CADASTRADA NO SISTEMA
              COM O ID PASSADO NO PARAMETRO DE ENTRADA , O SISTEMA
              DEVERA ACIONAR UM LANCADOR TIPADO E IDENTIFICADO CONFORME
              ANTERIORMENTE.

        [ 4  ] RECUPERA INFORMA????ES DA TABELA IDE EMIT E WTOTAL
               PARA USO NAS VALIDA????ES E ISER????ES

        [ 5 ]  VERIFICA E VALIDA , SE N??O HOUVER NENHUMA VENDA OU O VALOR
               DO ID RECUPEADO FOR -1 OU NULL , O COALESCE AJUSTA O NULL||-1
               O SISTEMA ENTENDERA QUE NAO EXISTE UMA VENDA NA TABELA IDE PARA
               EFETUAR UMA TRANSA????O DE PAGAMENTO

               NA SEGUNDA VALIDACAO SE A SITUACAO DA VENDA ESTIVER
               DIFERENTE DE 0: ABERTA , ENTENDE-SE QUE A VENDA NAO PODE
               RECEBER TRANSA????ES DE PAGAMENTOS

        [ 6 ]  RECUPERA E SOMA TODO OS VALORES DA TABELA ZPAG
               PARA QUE SE RECUPERE E ARMAZENE TODOS OS VALORES JA EFETUADOS
               SE O VALOR PAGO FOR MAIOR OU IGUAL AO VALOR DO TOTAL DA
               VNF OU TOTAL DA VENDA OU DA OCORRENCIA FISCAL ,
               ENTENDE-SE QUE TUDO FOI PAGO.

        [ 7 ]  COME??A TODOS OS PROCESSOS DE CALCULOS
               SE O VALOR DIGITADO FOR MAIOR QUE O RESTANTE
               RESTANTE JA INICIA COM O ( TOTAL PAGO RECUPERADO - VALOR TOTAL DA VNF )
               SE FOR ENTENDE-SE QUE ESTOU TRANSACIONANDO TODO O VALOR INFORMADO
               O VALOR DA TRANSACAO OU MAIS (  SE FOR MAIS GERAR TROCO )

        [ 8 ] REGISTRAR O PAGAMENTO DA VENDA NA TABELA ZPAG

        [ 9 ]  APOS A TRANSA????O OCORRER VERIFICAR SE TEM TROCO SE TIVER TROCO
               GRAVAR NA TABELA WTOTAL O TROCO DA VENDA

       [ 10 ]  APOS A TRANSA????O OCORRER VERIFICAR SE TUDO FOI PAGO,
               SE HOUVE O PAGAMENTO TOTAL DA VENDA, MODIFICAR O STATUS DA
               VENDA NA TABELA IDE PARA 1 = FECHADA

       [ 11 ]  APOS A TRANSA????O OCORRER COME??AR A GRAVAR OS VALORES
               DE SESS??O DO CAIXA AO FECHAR UMA VENDA IREMOS ENTAO ATUALIZAR AS POSICOES
               DE CAIXA DO LIVRO DE MOVIMENTO DE CAIXA
               RECUPERAR O ID DO CAIXA E ID DE SESS??O DA TABELA IDE
               RECUPERAR OS VALORES DO CAIXA ATUAIS

       [ 12 ]  ATUALIZA AS POSI????ES DE SESSAO DE CAIXA.';

/* Following GRANT statetements are generated automatically */

GRANT SELECT ON FINALIZADORAS TO PROCEDURE REGISTRAPAGAMENTO;
GRANT SELECT,UPDATE ON IDE TO PROCEDURE REGISTRAPAGAMENTO;
GRANT SELECT ON EMIT TO PROCEDURE REGISTRAPAGAMENTO;
GRANT SELECT,UPDATE ON WTOTAL TO PROCEDURE REGISTRAPAGAMENTO;
GRANT SELECT,INSERT ON ZPAG TO PROCEDURE REGISTRAPAGAMENTO;
GRANT EXECUTE ON PROCEDURE ATTCAIXA_OPVENDA TO PROCEDURE REGISTRAPAGAMENTO;

/* Existing privileges on this procedure */

GRANT EXECUTE ON PROCEDURE REGISTRAPAGAMENTO TO SYSDBA;
