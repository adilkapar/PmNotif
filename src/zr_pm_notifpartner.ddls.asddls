@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Notification Partner (Child Entity)'

define view entity ZR_PM_NotifPartner
  as select from Zv_PM_Notifpartner as partner
  association to parent ZR_PM_NOTIF as _Notif on $projection.NotificationNo = _Notif.NotificationNo
{
  key partner.NotificationNo,
  key partner.PartnerFunction,
  key partner.PartnerCounter,
      partner.Partner,

      _Notif
}