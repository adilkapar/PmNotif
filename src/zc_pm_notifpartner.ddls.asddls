@EndUserText.label: 'Notification Partner'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED

define view entity ZC_PM_NotifPartner
  as projection on ZR_PM_NotifPartner
{
  key NotificationNo,
  key PartnerFunction,
  key PartnerCounter,

      @EndUserText.label: 'Partner'
      @Consumption.valueHelpDefinition: [{
          entity: { name: 'ZI_PM_BM_Partner', element: 'Partner' }
      }]
      Partner,

      _Notif : redirected to parent ZC_PM_NOTIF
}