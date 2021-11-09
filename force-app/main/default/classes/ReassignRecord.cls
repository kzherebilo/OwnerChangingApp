public without sharing class ReassignRecord implements
        Database.Batchable<SObject>, Database.Stateful {
    
    public  String                              oldOwnerName;
    public  String                              newOwnerName;
    public  String                              notificationName;
    public  String                              emailTemplateName;
    public  Boolean                             enableEmails;
    public  List<String>                        emailAddressList;
    
    private String                              oldOwnerId;
    private String                              newOwnerId;
    private User                                apexJobOwner;
    private List<String>                        objectNameList;
    private Integer                             numberOfRecordsUpdated;
    private Integer                             numberOfRecordsProcessed;
    private List<Record_Reassignment_Task__c>   sfLog;
    private AsyncApexJob                        finishedApexJob;
    private CustomNotificationType              notificationType;
    private EmailTemplate                       emailVfTemplate;


    public ReassignRecord(String oldOwnerId, String newOwnerId,
            List<String> objectNameList) {
        this.oldOwnerId = oldOwnerId;
        this.newOwnerId = newOwnerId;
        this.objectNameList = objectNameList;
        this.oldOwnerName = '';
        this.newOwnerName = '';
        this.enableEmails = false;
        this.notificationName = 'Record_Reassignment_Notification';
        this.emailTemplateName = 'Record_Reassignment_Email_Template';
        this.numberOfRecordsProcessed = 0;
        this.numberOfRecordsUpdated = 0;
        this.emailAddressList = new List<String> ();
        this.sfLog = new List<Record_Reassignment_Task__c> ();
        try {
            this.notificationType = this.getCustomNotificationType(
                this.notificationName);
        }
        catch (Exception e) {
            this.exceptionHandler(e);
        }
        try {
            this.emailVfTemplate = this.getCustomEmailTemplate(
                this.emailTemplateName);
        }
        catch (Exception e) {
            this.exceptionHandler(e);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String oldOwnerId = this.oldOwnerId;
        if (this.apexJobOwner == null) {
            this.apexJobOwner = this.getApexJob(context).CreatedBy;
        }
        if (this.emailAddressList.isEmpty() && this.apexJobOwner != null) {
            this.emailAddressList.add(apexJobOwner.Email);
        }
        String query = 'SELECT OwnerId FROM ' + this.objectNameList[0]
            + ' WHERE OwnerId=:oldOwnerId';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<sObject> records) {
        for (sObject record : records) {
            record.put('OwnerId', this.newOwnerId);
        }
        List<Database.SaveResult> results = Database.update(records, false);
        for (Database.SaveResult result : results) {
            this.numberOfRecordsProcessed ++;
            if (result.isSuccess()) {
                this.numberOfRecordsUpdated++;
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        this.finishedApexJob = this.getApexJob(context);
        this.logTaskResults();
        this.resetTaskContext();
        this.chainApexJob();
    }



    /**************************************************************************/
    /***************************** HELPER METHODS *****************************/
    /**************************************************************************/

    private void emailReport() {
        if (!this.enableEmails) return;
        if (this.emailAddressList.isEmpty()) return;
        if (this.emailVfTemplate == null) return;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Record_Reassignment_Task__c logHeadRecord = this.getLogHead();
        mail.setTemplateId(this.emailVfTemplate.Id);
        mail.setToAddresses(this.emailAddressList);
        mail.setTargetObjectId(this.apexJobOwner.Id);
        mail.setWhatId(logHeadRecord.Id);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch (System.EmailException ex) {
            logHeadRecord.Error_Type__c += 'MAIL;';
            logHeadRecord.Error_Code__c += ex.getDmlType(0) + ';';
            logHeadRecord.Error_Description__c += ex.getDmlMessage(0) + ';';
            this.popLog();
            this.pushLog(logHeadRecord);
            update logHeadRecord;
        }
    }

    private void publishReport() {
        if (this.sfLog.isEmpty()) return;
        Record_Reassignment_Task__c logHeadRecord;
        logHeadRecord = this.sfLog[this.sfLog.size() - 1];
        Update_Owner_Event__e updateOwnerEvent = new Update_Owner_Event__e (
            oldOwnerName__c = this.oldOwnerName,
            newOwnerName__c = this.newOwnerName,
            jobId__c = logHeadRecord.Apex_Job_Id__c,
            jobStatus__c = logHeadRecord.Status__c,
            objectName__c = logHeadRecord.Object_Type__c,
            recordsProcessed__c = logHeadRecord.Number_Of_Records_Processed__c,
            recordsUpdated__c = logHeadRecord.Number_Of_Records_Updated__c,
            errorCode__c = logHeadRecord.Error_Code__c,
            errorType__c = logHeadRecord.Error_Type__c,
            errorMessage__c = logHeadRecord.Error_Description__c
        );
        if (this.objectNameList.size() == 0) {
            updateOwnerEvent.jobStatus__c += 'Final';
        }
        Database.SaveResult publishingResult = Eventbus.publish(updateOwnerEvent);
    }

    private void ringTheBell() {
        if (this.notificationType == null) return;
        if (this.apexJobOwner == null) return;
        Record_Reassignment_Task__c logHeadRecord = getLogHead();
        if (logHeadRecord == null) return;
        String targetId = logHeadRecord.Id;
        Set<String> recipientIdLSet = new Set<String> {apexJobOwner.Id};
        Messaging.CustomNotification notification;     
        notification = new Messaging.CustomNotification();
        notification.setTitle('Record reassignment ' + logHeadRecord.Status__c);
        notification.setBody(
            'There have been ' 
            + logHeadRecord.Number_Of_Records_Updated__c + ' '
            + logHeadRecord.Object_Type__c + ' records updated!');
        notification.setNotificationTypeId(this.notificationType.Id);
        notification.setTargetId(targetId);
        try {
            notification.send(recipientIdLSet);
        }
        catch (Exception e) {
            this.exceptionHandler(e);
        }
    }

    private void logTaskResults() {
        Record_Reassignment_Task__c newLogRecord;
        newLogRecord = new Record_Reassignment_Task__c();
        newLogRecord.Status__c = this.finishedApexJob.Status;
        newLogRecord.Apex_Job_Id__c = this.finishedApexJob.Id;
        newLogRecord.Previous_Owner__c = this.oldOwnerId;
        newLogRecord.New_Owner__c = this.newOwnerId;
        newLogRecord.Object_Type__c = this.objectNameList[0];
        newLogRecord.Number_Of_Records_Processed__c = this.numberOfRecordsProcessed;
        newLogRecord.Number_Of_Records_Updated__c = this.numberOfRecordsUpdated;
        newLogRecord.Apex_Batches_Processed__c = this.finishedApexJob.JobItemsProcessed;
        newLogRecord.Apex_Total_Batches__c = this.finishedApexJob.TotalJobItems;
        if (this.finishedApexJob.NumberOfErrors > 0) {
            newLogRecord.Error_Type__c = 'APEX;';
            newLogRecord.Error_Description__c = this.finishedApexJob.ExtendedStatus;
        }
        this.sfLog.add(newLogRecord);
    }

    private void resetTaskContext() {
        this.numberOfRecordsUpdated = 0;
        this.numberOfRecordsProcessed = 0;
        this.objectNameList.remove(0);
    }

    private void chainApexJob() {
        Record_Reassignment_Task__c logHeadRecord = this.popLog();

        if (this.objectNameList.size() > 0) {
            Database.executeBatch(this);
        }
        insert logHeadRecord;
        this.pushLog(logHeadRecord);
        this.ringTheBell();
        this.emailReport();
        this.publishReport();
    }

    private AsyncApexJob getApexJob(Database.BatchableContext context) {
        return [SELECT Id, Status, NumberOfErrors, ExtendedStatus,
            JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id=:context.getJobId()];
    }

    private CustomNotificationType getCustomNotificationType(String notificationName) {
        return [SELECT Id, DeveloperName FROM CustomNotificationType
            WHERE DeveloperName =: notificationName];
    }

    private EmailTemplate getCustomEmailTemplate(String emailTemplateName) {
        return [SELECT Id, DeveloperName FROM EmailTemplate
            WHERE DeveloperName =: emailTemplateName];
    }

    private Record_Reassignment_Task__c popLog() {
        Record_Reassignment_Task__c logHeadRecord;
        if (!this.sfLog.isEmpty()) {
            logHeadRecord = this.sfLog.remove(this.sfLog.size() - 1);
        }
        return logHeadRecord;
    }

    private Record_Reassignment_Task__c getLogHead() {
        Record_Reassignment_Task__c logHeadRecord;
        if (!this.sfLog.isEmpty()) {
            logHeadRecord = this.sfLog[this.sfLog.size() - 1];
        }
        return logHeadRecord;
    }

    private void pushLog(Record_Reassignment_Task__c record) {
        this.sfLog.add(record);
    }

    private void exceptionHandler(Exception e) {

    }
}
