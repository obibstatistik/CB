### DOC

#### Mål for tilgængelighed af overbygningsmaterialer
Danske bøger skal være tilgængelige for udlån max. 17 arbejdsdage og udenlandske bøger max 25 arbejdsdage efter bestilling hos leverandør.
•	CB’erne udarbejder stikprøve i uge 18 over leveringstiden på baggrund af de første 25 udenlandske titler indkøbt i uge 11 og de første 25 danske titler indkøbt i uge 14.
•	CB’erne udarbejder stikprøve i uge 41 over leveringstiden på baggrund af de første 25 udenlandske titler indkøbt i uge 34 og de første 25 danske titler indkøbt i uge 38.

Table
```SQL
drop table if exists datamart.accession_lev_tid_mat;
select acqno, vndcustomerid, min(dage) as dage into datamart.accession_lev_tid_mat from 
(
select acq.acqno,acq.keyno,acq.orddate,stockdate, vndcustomerid,
  (		
  select count(*) from datamart.arbejdsdage
  where dato between acq.orddate and stockdate
  ) as dage
from acq 
join holding on holding.acqno = acq.acqno
where vndcustomerid in  ('422451','428094')
order by acqno, vndcustomerid
) dk
group by acqno, dage, vndcustomerid
order by acqno;
```

#### Mål for leveringstid for reserverede overbygningsmaterialer
Ved mere end 3 reserveringer pr. eksemplar skal materialet suppleres. Hvis dette ikke er muligt skal reserveringen videresendes til et andet centralbibliotek, hvor materialet er tilgængeligt eller til Statsbiblioteket. Dette gælder dog ikke bestsellere, film og lydbøger. 

Table
```SQL
drop table if exists datamart.accession_lev_tid_res;
select title as Titel, txt.lang as Sprog , resitem.keyno as Idnummer, count(distinct resitem.resno) as Reserveringer, Eksemplarer, (count(distinct resitem.resno) / eksemplarer) as R_pr_E into datamart.accession_lev_tid_res from resitem
join (select keyno,count(copyno) as eksemplarer from holding where dep in ('ocv','ocb') group by keyno) as holding_odense on holding_odense.keyno = resitem.keyno
join res on res.resno = resitem.resno
join (select key, title, imat, lang from txtif) as txt on txt.key = resitem.keyno
where (resbranch like '%hb%' 
or resbranch like '%da%'
or resbranch like '%ta%'
or resbranch like '%bo%'
or resbranch like '%kor%'
or resbranch like '%vo%'
or resbranch like '%ho%'
or resbranch like '%hoj%'
or resbranch like '%mus%'
or resbranch like '%lok%')
and ((txt.imat != 'vd' and txt.imat != 'lc') or txt.imat IS NULL)
group by title, resitem.keyno,eksemplarer,lang
order by R_pr_E desc;
```

#### Mål for leveringstid på ikke-udlånte materialer
Der må max gå 24 timer fra et materiale er bestilt til det er afsendt fra centralbiblioteket hverdage og lørdage. Cb’erne udarbejder stikprøver i ugerne 18 og 41.
I ugerne 18 og 41 udskrives bestillingerne til andre biblioteker 2 gange dagligt. For at sikre validi-teten af målingerne skal der gerne være over 110 bestillinger.
Målet er at 95% af bestillingerne fra andre biblioteker skal være fremfundet og afsendt inden for 24 timer efter bestillingerne er modtaget.
Hver bestilling tjekkes i bibliotekssystemet for hvornår det er afsendt fra CB. Bestillinger inddeles i følgende grupper:
1.	Antal bestillinger afsendt samme dag som det er modtaget
2.	Antal bestillinger afsendt inden for 48 timer efter modtagelse
3.	Antal bestillinger afsendt efter 48 timer efter modtagelse eller slet ikke.

Table
```SQL
drop table if exists datamart.accession_lev_tid_bes;
select * into datamart.accession_lev_tid_bes from (
select cast('2017' as integer) as year, stat2017.resno, stat2017.cat, stat2017.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2017.stdate) as time from stat2017
join 
  (select * 
  from stat2017 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2017.resno 
where stat2017.type = '28' and stat2017.dep in ('ocv','ocb') and stat2017.cat not in ('vm','vo','pe','bo','bm')
union
select cast('2016' as integer) as year, stat2016.resno, stat2016.cat, stat2016.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2016.stdate) as time from stat2016
join 
  (select * 
  from stat2016 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2016.resno 
where stat2016.type = '28' and stat2016.dep in ('ocv','ocb') and stat2016.cat not in ('vm','vo','pe','bo','bm')
union
select cast('2015' as integer) as year, stat2015.resno, stat2015.cat, stat2015.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2015.stdate) as time from stat2015
join 
  (select * 
  from stat2015 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2015.resno 
where stat2015.type = '28' and stat2015.dep in ('ocv','ocb') and stat2015.cat not in ('vm','vo','pe','bo','bm')
order by year, time) as test; 
```
