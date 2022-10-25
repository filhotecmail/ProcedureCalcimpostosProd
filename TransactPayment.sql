EXECUTE BLOCK (
    IN_IDPK BIGINT = :IN_IDPK, /*INFORMAR O ID DA VENDA*/
    IN_Z001DATETIME TIMESTAMP = :IN_Z001DATETIME, /* INFORMAR A DATA E HORA NO FORMATO SQL TIME STAPMP */
    IN_Z002INDICEPAG INTEGER = :IN_Z002INDICEPAG, /* INFORMAR O INDICE DA FINALIZADORA DE PAGAMENTO O ID */
    IN_Z003VLDIGITADO NUMERIC(15,2) = :IN_Z003VLDIGITADO  /* INFORMAR O VALOR DIGITADO NA OPERACAO */
    )
 RETURNS (

    ID INTEGER ,
    IDPK BIGINT,
    Z001DATETIME TIMESTAMP ,
    Z002INDICEPAG INTEGER ,
    Z003VLDIGITADO NUMERIC(15,2),
    Z004VLREGISTRADO NUMERIC(15,2) ,
    Z005DESCPAG VARCHAR(60),
    Z006INDICESAT SMALLINT,
    ZRESTANTE NUMERIC(15,2) ,
    ZTROCO NUMERIC(15,2)

  )

AS

 DECLARE VARIABLE LINDICEPAGAMENTO INTEGER;
 DECLARE VARIABLE LIDPKEMPRESA BIGINT;
 DECLARE VARIABLE LFDESC VARCHAR(60);
 DECLARE VARIABLE LFINDICESAT SMALLINT;
 DECLARE VARIABLE LFEMITEDOCFIS SMALLINT;
 DECLARE VARIABLE SLINEBREAK CHAR(23);

 DECLARE VARIABLE LCNPJ VARCHAR(17);
 DECLARE VARIABLE LXNOME VARCHAR(60);
 DECLARE VARIABLE LXFANT VARCHAR(60);
 DECLARE VARIABLE LXLGR VARCHAR(60);
 DECLARE VARIABLE LIDVENDA TYPE OF COLUMN IDE.ID;
 DECLARE VARIABLE LW16VNF TYPE OF COLUMN WTOTAL.W16VNF;
 DECLARE VARIABLE LB005SIT TYPE OF COLUMN IDE.B005SIT;

 DECLARE VARIABLE LVLPAGO NUMERIC( 15,2 );


BEGIN
 SLINEBREAK  = ''||ASCII_CHAR(13) || ASCII_CHAR(10)||'';
 LVLPAGO = 0.00;

  IF ( :IN_IDPK IS NULL OR ( :IN_IDPK  <=  0 ) ) THEN
  EXCEPTION EEBADPARAM 'O VALOR IN_IDPK , ID DA VENDA NAO FOI INFORMADO! '
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_IDPK '
    ||' um valor nao foi informado, impossivel de filtrar por 0 ou vazio'
    ||:SLINEBREAK||' PARAMETRO :IN_IDPK ESTA NULL OU VALOR INVALIDO ! ';

  IF ( :IN_Z003VLDIGITADO IS NULL OR ( :IN_Z003VLDIGITADO  <=  0 ) ) THEN
  EXCEPTION EEBADPARAM 'O VALOR IN_Z003VLDIGITADO , VALOR DIGITADO NAO  FOI INFORMADO OU INFORMADO INCORRETAMENTE! '
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
  * VERIFICA E VALIDA , SE NÃO HOUVER NENHUMA FORMA DE PAGAMENTO CADASTRADA
  * NA TABELA O SISTEMA NAO VAI PROSSEGUIR
  *
 ***************************************************************************/

 IF ( COALESCE(LINDICEPAGAMENTO,-1) <= 0 ) THEN
  EXCEPTION EECRITICALFAIL 'NAO EXISTEM FORMAS DE PAGAMENTOS CADASTRADAS NO SISTEMA! '
    ||:SLINEBREAK||'Esse erro e: O parametro :IN_Z002INDICEPAG '
    ||' um valor foi informado, mas nao existe uma forma de pagamento cadastrada! '
    ||:SLINEBREAK||'TABELA FINALIZADORAS ESTA VAZIA ! ';

 /***************************************************************************
  * RECUPERA INFORMAÇÕES DA TABELA IDE EMIT E WTOTAL
  * PARA USO NAS VALIDAÇÕES E ISERÇÕES
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
  * VERIFICA E VALIDA , SE NÃO HOUVER NENHUMA VENDA OU O VALOR DO ID RECUPEADO
  * FOR -1 OU NULL , O COALESCE AJUSTA O NULL||-1
  * O SISTEMA ENTENDERA QUE NAO EXISTE UMA VENDA NA TABELA IDE PARA
  * EFETUAR UMA TRANSAÇÃO DE PAGAMENTO
  *
  * IF ( :LB005SIT  <> 0 ) THEN
  *
  * NA SEGUNDA VALIDACAO
  * SE A SITUACAO DA VENDA ESTIVER  DIFERENTE DE 0: ABERTA , ENTENDE-SE QUE
  * A VENDA NAO PODE RECEBER TRANSAÇÕES DE PAGAMENTOS
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
     EXCEPTION EECRITICALFAIL 'VENDA DE NUMERO '||:IN_IDPK||' NAO PODE SER MOVIMENTADA , '
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

  IF ( :LVLPAGO  >= :LW16VNF ) THEN
     EXCEPTION EECRITICALFAIL 'VENDA DE NUMERO '||:IN_IDPK||' JA TEVE TODO SEU VALOR REGISTRADO, '
    ||'A venda informada, teve seu valor total ja registrado.'
    ||:SLINEBREAK||'Esse erro e: O parametro :in_IDPK esta  '
    ||'associado a uma venda na tabela IDE ja paga '
    ||:SLINEBREAK||' REGISTRO BLOQUEADO | PAGAMENTO COMPLETO ';


 /***************************************************************************
  *
  * COMEÇA TODOS OS PROCESSOS DE CALCULOS
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
  * APOS A TRANSAÇÃO OCORRER
  * VERIFICAR SE TEM TROCO SE TIVER TROCO
  * GRAVAR NA TABELA WTOTAL O TROCO DA VENDA
 ***************************************************************************/
  IF (:ZTROCO > 0.00 ) THEN
    UPDATE WTOTAL SET W17AVTROCO = :ZTROCO
    WHERE (WTOTAL.IDPK = :IDPK);

 SUSPEND;

 /***************************************************************************
  * APOS A TRANSAÇÃO OCORRER
  * VERIFICAR SE TUDO FOI PAGO, SE HOUVE O PAGAMENTO TOTAL
  * DA VENDA, MODIFICAR O STATUS DA VENDA NA TABELA IDE PARA 1 = FECHADA
 ***************************************************************************/

 SELECT
  COALESCE(SUM(ZZ.Z004VLREGISTRADO),0.00)
   FROM ZPAG ZZ WHERE ZZ.IDPK = :IN_IDPK  INTO :LVLPAGO;
  IF ( :LVLPAGO  >= :LW16VNF ) THEN
  UPDATE IDE SET B005SIT = 1 WHERE (IDE.ID = :IDPK);

END
