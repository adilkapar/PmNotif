@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_PM_NOTIF
  provider contract transactional_query
  as projection on ZR_PM_NOTIF
{
      @Search.defaultSearchElement: true
  key NotificationNo,
      NotifType,
      Plant,
      //      WcPlant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_Equipment', element: 'EquipmentNo' } }]
      EquipmentNo,
      EquipmentDesc,
      ShortText,
      ReportedBy,
      ReporterName,
      CreationDate,
      CreationTime,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_StoppageReason', element: 'BasicCodeGroup'},
      additionalBinding: [{localElement: 'plant', element: 'Plant', usage: #FILTER}]}]
      BasicCodeGroup,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_StoppageReason', element: 'BasicCode' },
      additionalBinding: [
          { localElement: 'plant', element: 'Plant', usage: #FILTER},
          { localElement: 'BasicCodeGroup',  element: 'BasicCodeGroup' }] }]
      BasicCode,
      BasicCodeText,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_StoppageReason', element: 'DetailCodeGroup' },
        additionalBinding: [
          { localElement: 'plant', element: 'Plant', usage: #FILTER},
          { localElement: 'BasicCodeGroup',  element: 'BasicCodeGroup' },
          { localElement: 'BasicCode',  element: 'BasicCode' }] }]
      DetailCodeGroup,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_StoppageReason', element: 'DetailCode' },
        additionalBinding: [
          { localElement: 'plant', element: 'Plant', usage: #FILTER},
          { localElement: 'BasicCodeGroup',  element: 'BasicCodeGroup' },
          { localElement: 'BasicCode',  element: 'BasicCode' },
          { localElement: 'DetailCode',  element: 'DetailCode' }] }]
      DetailCode,
      DetailCodeText,

      ProcessingPhase,
      ProcessingPhaseDesc,
      RequiredEndDate,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_WorkCenter', element: 'WorkCenter' },
      additionalBinding: [
          { localElement: 'Plant', element: 'Plant' } ] } ]
      WorkCenter,
      WorkCenterText,
      MaintenanceOrder,
      Breakdown,

      // FIX: Use the composition name from the base view (_Partner) and redirect it.
      _Partner : redirected to composition child ZC_PM_NotifPartner

}
