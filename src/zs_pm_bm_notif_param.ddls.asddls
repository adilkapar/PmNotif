@EndUserText.label: 'Notification Create Parameters'
define abstract entity ZS_PM_BM_NOTIF_PARAM
{
  @EndUserText.label: 'Notification Type'
  @UI.defaultValue: 'BM'
  NotifType    : qmart;

  @EndUserText.label: 'Notification Text'
  SHORT_TEXT   : qmtxt;

  @EndUserText.label: 'Plant'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Plant', element: 'Plant' } }]
  Plant        : werks_d;

  @EndUserText.label: 'Equipment'
  @Consumption.valueHelpDefinition: [{
       entity  : { name: 'ZI_PM_BM_Equipment', element: 'EquipmentNo' },
       additionalBinding: [{ localElement: 'Plant', element: 'Plant' }],
       presentationVariantQualifier: '',
       useForValidation: true
       }]
  Equipment    : equnr;

  //  @EndUserText.label: 'Work Center'
  //  @Consumption.valueHelpDefinition: [{
  //      entity   : { name: 'ZI_PM_BM_WorkCenter', element: 'WorkCenter' },
  //      additionalBinding: [{ localElement: 'Plant', element: 'Plant' }]
  //  }]
  //  WorkCenter   : arbpl;

  @EndUserText.label: 'Basic Stoppage Code Group'
  @UI.defaultValue: 'Y1'
  @UI.hidden: true
  @Consumption.valueHelpDefinition: [{
    entity     : { name: 'ZI_PM_BM_StoppageReason', element: 'BasicCodeGroup' },
    additionalBinding: [
    { localElement: 'Plant', element: 'Plant' },
    { localElement: 'dl_codegrp', element: 'BasicCodeGroup' },
    { localElement: 'd_codegrp',  element: 'DetailCodeGroup' },
    { localElement: 'd_code',     element: 'DetailCode' },
    { localElement: 'dl_code_text',    element: 'BasicStoppageText' },
    { localElement: 'd_code_text',     element: 'DetailStoppageText' }
    ]
  }]
  dl_codegrp   : qcodegrp;

  @EndUserText.label: 'Basic Stoppage Code'
  @Consumption.valueHelpDefinition: [{
      entity   : { name: 'ZI_PM_BM_BasicStoppage', element: 'BasicCode' },
      additionalBinding: [
          { localElement: 'Plant', element: 'Plant', usage: #FILTER},
          { localElement: 'dl_codegrp', element: 'BasicCodeGroup' },
          { localElement: 'dl_code_text',    element: 'BasicStoppageText' }
      ]
  }]
  @ObjectModel.text.element: ['dl_code_text']
  @UI.textArrangement: #TEXT_LAST
  dl_code      : qcode;
  @EndUserText.label: 'Basic Stoppage Text'
  @UI.hidden   : true
  @Semantics.text: true // Ayrı alan olarak GİZLE
  dl_code_text : qtxt_code;

  @EndUserText.label: 'Detail Stoppage Code Group'
  @UI.defaultValue: 'Y2'
  @UI.hidden: true
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_StoppageReason', element: 'DetailCodeGroup' },
      additionalBinding: [
          { localElement: 'Plant', element: 'Plant', usage: #FILTER},
          { localElement: 'dl_codegrp', element: 'BasicCodeGroup' },
          { localElement: 'dl_code',    element: 'BasicCode' },
          { localElement: 'd_code',     element: 'DetailCode' },
          { localElement: 'dl_code_text',    element: 'BasicStoppageText' },
          { localElement: 'd_code_text',     element: 'DetailStoppageText' }
      ] }]
  d_codegrp    : qcodegrp;

  @EndUserText.label: 'Detail Stoppage Code'
  @Consumption.valueHelpDefinition: [{
      entity   : { name: 'ZI_PM_BM_DetailStoppage', element: 'DetailCode' },
      additionalBinding: [
          { localElement: 'Plant', element: 'Plant', usage: #FILTER},
          { localElement: 'dl_codegrp', element: 'BasicCodeGroup', usage: #FILTER },
          { localElement: 'dl_code',    element: 'BasicCode', usage: #FILTER },
          { localElement: 'd_codegrp',  element: 'DetailCodeGroup' },
          { localElement: 'd_code_text',     element: 'DetailStoppageText' }
      ]
  }]
  @ObjectModel.text.element: ['d_code_text']
  @UI.textArrangement: #TEXT_LAST
  d_code       : qtxt_code;
  @EndUserText.label: 'Detail Stoppage Text'
  @UI.hidden   : true
  @Semantics.text: true
  d_code_text  : qtxt_code; // veya uygun text tipi

  @EndUserText.label: 'Breakdown Indicator'
  breakdown    : msaus;
}