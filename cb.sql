/* leveringstid*/

drop table if exists datamart.accession_lev_tid_mat;
select acqno, vndcustomerid, 
(CASE 
WHEN vndcustomerid in ('422451','422454','428070','428078','428086','428094','428946','428950','436018','525263') THEN 'DK'
WHEN vndcustomerid in ('74610072','74610073') THEN 'UDL'
ELSE 'Error'
END) as dkudl, orddate::timestamp::date,
min(dage) as dage into datamart.accession_lev_tid_mat from 
(
select acq.acqno,acq.keyno,acq.orddate,stockdate,vndcustomerid,
  (		
  select count(*) from datamart.arbejdsdage
  where dato between acq.orddate and stockdate
  ) as dage
from acq 
join holding on holding.acqno = acq.acqno
where vndcustomerid in  ('422451','422454','428070','428078','428086','428094','428946','428950','436018','525263','74610072','74610073')
order by acqno, vndcustomerid
) dk
group by acqno, dage, vndcustomerid, year, week, orddate
order by acqno;

/* leveringstid for reserverde materialer */

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

/* leveringstid for ikke udlånte materialer*/

drop table if exists datamart.accession_lev_tid_bes;
select * into datamart.accession_lev_tid_bes from (
select cast('2017' as integer) as year, stat2017.resno, stat2017.cat, stat2017.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2017.stdate) as time, EXTRACT(epoch FROM (nested.stdate-stat2017.stdate))/3600 as days from stat2017
join 
  (select * 
  from stat2017 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2017.resno 
where stat2017.type = '28' and stat2017.dep in ('ocv','ocb') and stat2017.cat not in ('vm','vo','pe','bo','bm')
union
select cast('2016' as integer) as year, stat2016.resno, stat2016.cat, stat2016.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2016.stdate) as time, EXTRACT(epoch FROM (nested.stdate-stat2016.stdate))/3600 as days from stat2016
join 
  (select * 
  from stat2016 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2016.resno 
where stat2016.type = '28' and stat2016.dep in ('ocv','ocb') and stat2016.cat not in ('vm','vo','pe','bo','bm')
union
select cast('2015' as integer) as year, stat2015.resno, stat2015.cat, stat2015.stdate as stdate28, nested.stdate as stdate43, (nested.stdate-stat2015.stdate) as time, EXTRACT(epoch FROM (nested.stdate-stat2015.stdate))/3600 as days from stat2015
join 
  (select * 
  from stat2015 
  where type = '43' and dep in ('ocv','ocb')
  ) as nested on nested.resno = stat2015.resno 
where stat2015.type = '28' and stat2015.dep in ('ocv','ocb') and stat2015.cat not in ('vm','vo','pe','bo','bm')
order by year, time) as test; 
