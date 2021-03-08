Indikatoren
===========

Indikatoren
-----------

- Quorum (0%-100%, num of signature relative to eligible population) (Eder, Vatter und Freitag 2009; Leemann 2015)
- Circulation Time (0-∞) (Eder, Vatter und Freitag 2009)
- Mobilisation coefficient: Quorum / Circulation Time (Moser 1985; Eder, Vatter und Freitag 2009)
- Offenheitsindex (Eder und Magin 2008)
- Demokratieindex (Stutzer 1999)
- subnational Direct Democracy Index (snDDI) (Leemann und Stadelmann-Steffen working paper)

Literatur
---------

Leemann, L. (2015). Political Conflict and Direct Democracy: Explaining Initiative Use 1920-2011. Swiss Political Science Review, 21(4), 596–616. https://doi.org/10.1111/spsr.12190

    - signature requirements 50 000 and after womens' suffrage 100 000 but changing percentage of eligible population because of population growth

Eder, C., Vatter, A., & Freitag, M. (2009). Institutional Design and the Use of Direct Democracy: Evidence from the German Länder. West European Politics, 32(3), 611–633. https://doi.org/10.1080/01402380902779139

	- use quorum, circulation time and mobilisation coefficient to analze how institutional openness affects initiative use

Eder, C., & Magin, R. (2008). Volksgesetzgebung in den deutschen Bundesländern: ein Vorschlag zu ihrer empirischen Erfassung aus subnational-vergleichender Perspektive. Zeitschrift für Parlamentsfragen, 39(2), 358–378.

    - propose a detailed coding scheme to create an "Offenheitsindex"

Stutzer, A. (1999). Demokratieindizes für die Kantone der Schweiz. Working paper series / Institute for Empirical Research in Economics. http://www.econ.uzh.ch/wp.html

	- propose a simpler coding scheme for a "Demokratieindex"

Moser, Christian (1985). Institutionen und Verfahren der Rechtsetzung in den Kantonen. Bern: Forschungszentrum für Schweizerische Politik.

	- proposed the mobilisation coefficient

Variablen (institutional openness)
----------------------------------
CODEBOOK:

- volksgesetzgebung (nein = 0, ja = 1)
- stufen (zweistufig = 2, dreistufig = 3)
- unterschriftenquorum_vi_abs (in absoluten Zahlen)
- eligible_population (wird benötigt um Quroum in % zu berechnen falls absolute Unterschriftenzahl gilt) 
- unterschriftenquorum_vi (% der abstimmunsberechtigten Bevölkerung)
- sammelfrist_vi (in Tagen)
- mobilisierungskoeffizient_vi (unterschriftenquorum_vi / sammelfrist_vi)
- unterschriftenquorum_vb (% der abstimmungsberechtigten Bevölkerung)
- sammelfrist_vb (in Tagen)
- mobilisierungskoeffizient_vb (unterschriftenquorum_vb / sammelfrist_vb)
- amtseintragung_vi (ja/nein Amtseintragung vs. freie Sammlung)
- amtseintragung_vb (ja/nein Amtseintragung vs. freie Sammlung)

Variablen (nice to have)
------------------------

- verfassungsänderung (VE über Verfassungsänderung möglich; 0 = nein, 1 = ja)
- finanztabu (nein = 0, ja = 1)
- beteiligungsquorum (% der abstimmungsberechtigten Bevölkerung, Na wenn keines vorhanden)
- beteiligungsquorum_verf (% der abstimmungsberechtigten Bevölkerung bei verfassungsänderndem Referendum)
- zustimmungsquorum (% der abstimmungsberechtigten Bevölkerung, 0 wenn keines vorhanden)
- zustimmungsqourum_verf (% der abstimmungsberechtigten Bevölkerung bei verfassungsänderndem Referendum)