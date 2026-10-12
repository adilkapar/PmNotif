@EndUserText.label: 'Assign Employee Parameters'
define abstract entity ZS_PM_BM_ASSIGN
{
  @EndUserText.label: 'User Responsible (VU)'
  @Consumption.valueHelpDefinition: [{
      entity: { name: 'ZI_PM_BM_Partner', element: 'Partner' }
  }]
  Partner  : xubname; 
}