@echo off

echo Moving html files to %filename%

cd c:\Users\Bojan.Popovic\Desktop\AutomationResults
set filename=reSluts %date% %time%
set filename=%filename:/=-%
set filename=%filename: =__%
set filename=%filename:.=_%
set filename=%filename::=-%

copy C:\CloudMigrationPlatform\Devtech.ExchangeMigrator\CloudMesh.Ui.AutomatedTests\TestResults\Html\*.html c:\Users\Bojan.Popovic\Desktop\AutomationResults\%filename%