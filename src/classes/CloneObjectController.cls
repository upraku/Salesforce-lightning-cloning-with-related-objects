public with sharing class CloneObjectController {
    @AuraEnabled
    public static String cloneSingleObject(String recordId){
        System.debug('--------Inside Controller:'+recordId);
        SObject newClonedObject = GlobalSObjectUtility.cloneSingleObject((Id)recordId);
        insert newClonedObject;
        System.debug('--------------:'+newClonedObject.Id);
        return newClonedObject.Id;
    }

    @AuraEnabled
    public static String cloneWithRelatedObjects(String recordId){
        SObject newClonedObject = GlobalSObjectUtility.cloneWithRelated((Id)recordId);
        return newClonedObject.Id;
    }

    @AuraEnabled
    public static Boolean isCloningPossible(String recordId){
        String sObjectAPIName = GlobalSObjectUtility.getSObjectAPINameFromId((Id)recordId);
        if(sObjectAPIName == 'Catalogue_Program__c'){
            return isProgramCloneable((Id)recordId);
        }else if(sObjectAPIName == 'Catalogue_Subject__c'){
            return isSubjectCloneable((Id)recordId);
        }
        return true;
    }


    private static Boolean isProgramCloneable(Id programId){
        String programStatus = 'Published - Live';

        Catalogue_Program__c catProgram = [SELECT Id, status__c, Year__c FROM Catalogue_Program__c WHERE Id =: programId];
        if (catProgram.Status__c == programStatus) {
            return true;
        }else{
            return false;
        }
    }

    private static Boolean isSubjectCloneable(Id programId){
        String subjectStatus = 'Published - Live';

        Catalogue_Subject__c catSubject = [SELECT Id, status__c, Year__c FROM Catalogue_Subject__c WHERE Id =: programId];
        if (catSubject.Status__c == subjectStatus) {
            return true;
        }else{
            return false;
        }
    }
}