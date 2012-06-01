#!/bin/bash
mysql -u test -pGim9p6gW test -e "DELETE FROM users WHERE id_ISP  IN (SELECT id from ISPs WHERE name = 'euNetworks Services GmbH');"
mysql -u test -pGim9p6gW test -e "DELETE FROM users where id_code IN (SELECT ID FROM codes WHERE code IN ('cZj', '23m'));" 
mysql -u test -pGim9p6gW test -e "DELETE FROM users WHERE update_date <= DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 28 DAY) AND mysex IN (1,6);;"
mysql -u test -pGim9p6gW test -e "DELETE FROM users WHERE id_code IN (SELECT id FROM codes WHERE update_date <= DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 18 DAY)) AND mysex IN (1, 6);"
mysql -u test -pGim9p6gW test -e "DELETE FROM users WHERE id_code IN (SELECT id FROM codes WHERE update_date <= DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)) AND mysex IN (2, 7);"
mysql -u test -pGim9p6gW test -e "DELETE FROM codes WHERE id NOT IN (SELECT distinct id_code from users);"
