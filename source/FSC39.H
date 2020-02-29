* FSC-0039 packet header

         offset   0

pk_onode ds.w     1        origination node
pk_dnode ds.w     1        destination node
pk_year  ds.w     1        year  \
pk_month ds.w     1        month  \
pk_day   ds.w     1        day     \
pk_hour  ds.w     1        hour      of packet creation
pk_min   ds.w     1        minute  /
pk_sec   ds.w     1        second /
pk_baud  ds.w     1        baud (unused)
pk_versn ds.w     1        packet version (always 2)
pk_onet  ds.w     1        origination net
pk_dnet  ds.w     1        destination net
pk_prdcl ds.b     1        product code (lsb)
pk_prdrh ds.b     1        product revision (major)
pk_pwd   ds.b     8        packet password
pk_qozon ds.w     1        origination zone (QMail/ZMailQ)
pk_qdzon ds.w     1        destination zone (QMail/ZMailQ)
pk_spare ds.w     1        spare
pk_capvl ds.w     1        capability validation word (byte-swapped)
pk_prdch ds.b     1        product code (msb)
pk_prdrl ds.b     1        product revision (minor)
pk_capwd ds.w     1        capability word
pk_ozone ds.w     1        origination zone
pk_dzone ds.w     1        destination zone
pk_opnt  ds.w     1        origination point
pk_dpnt  ds.w     1        destination point
pk_data  ds.l     1        product-specific data
pk_hdlen equ      *        packet header length

PKTVERS  equ      2
CAPWD    equ      $100     byte-swapped (INTEL order)
FRODO    equ      $0C
DBRIDGE  equ      $1A
QMAIL    equ      $29
ZMAILQ   equ      $35
TOSSCAN  equ      $3F
XRS      equ      $45
QBOXMAIL equ      $54

