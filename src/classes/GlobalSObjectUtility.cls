global class GlobalSObjectUtility {
    public static SObject cloneSingleObject(Id recordId){
        String sObjectAPIName = getSObjectAPINameFromId(recordId);

        List<String> fieldsTobeIgnored = fieldsIgnoredWhileCloning(sObjectAPIName);

        List<String> fieldAPINames = getAllFieldsAPIName(sObjectAPIName, fieldsTobeIgnored);

        String whereCondition = ' WHERE Id = \''+recordID + '\'';
        SObject objectToBeCloned = getSObjectData(sObjectAPIName,fieldAPINames, whereCondition)[0];

        SObject newObject = cloneObject(objectToBeCloned);
        newObject = setDefaultValues(fieldAPINames, objectToBeCloned, newObject);
        return newObject;
    }

    private static SObject setDefaultValues(List<String> fieldAPINames,SObject parentObject, SObject clonedObject){
        if(fieldAPINames.contains('cloned_from__c')){
            clonedObject.put('cloned_from__c',parentObject.Id);
        }
        if(fieldAPINames.contains('version__c') && parentObject.get('version__c') != null){
            clonedObject.put('version__c',Integer.valueOf(parentObject.get('version__c')) + 1);
        }
        return clonedObject;
    }

    public static SObject cloneWithRelated(Id recordId){
        String sObjectAPIName = getSObjectAPINameFromId(recordId);
        SObject newParentObject = cloneSingleObject(recordId);
        insert newParentObject;
        List<Cloning_Configuration__mdt> cloneConfigs = getCloningConfiguration(sObjectAPIName);
        if(cloneConfigs.size()>0){
            cloneObjectWithRelated(recordId,cloneConfigs, newParentObject.Id);
        }
        return newParentObject;
    }

    private static void cloneObjectWithRelated(Id originalRecordId, List<Cloning_Configuration__mdt> relatedObjects, Id clonedParentRecordId){
        for(Cloning_Configuration__mdt cloningConfigdata : relatedObjects){
            List<String> fieldsTobeIgnored = fieldsIgnoredWhileCloning(cloningConfigdata.ChildObject__c);

            List<String> fieldAPINames = getAllFieldsAPIName(cloningConfigdata.ChildObject__c, fieldsTobeIgnored);

            String fieldName = cloningConfigdata.LinkingField__c;
            String whereCondition =' WHERE '+ fieldName + ' = \'' + originalRecordId + '\'';
            List<SObject> objectsToBeCloned = getSObjectData(cloningConfigdata.ChildObject__c,fieldAPINames, whereCondition);
            List<Cloning_Configuration__mdt> cloneConfigs = getCloningConfiguration(cloningConfigdata.ChildObject__c);
            for(SObject obj : objectsToBeCloned){
                SObject newSObject = cloneObject(obj);
                newSObject.put(fieldName,clonedParentRecordId);
                newSObject = setDefaultValues(fieldAPINames, obj, newSObject);
                insert newSObject;
                if(cloneConfigs.size() > 0){
                    cloneObjectWithRelated(obj.Id, cloneConfigs, newSObject.Id);
                }
            }
        }
        return;
    }

    static Map<String, List<Cloning_Configuration__mdt>> cloningConfigsCache = new Map<String, List<Cloning_Configuration__mdt>>();
    private static List<Cloning_Configuration__mdt> getCloningConfiguration(String parent){
        List<Cloning_Configuration__mdt> cloningConfigs = new List<Cloning_Configuration__mdt>();

        if(cloningConfigsCache.containsKey(parent)){
            cloningConfigs = cloningConfigsCache.get(parent);
        }else{
            cloningConfigs = [SELECT ParentObject__c,ChildObject__c, LinkingField__c, WhereCondition__c FROM Cloning_Configuration__mdt WHERE ParentObject__c =: parent];
            if(cloningConfigs.size() > 0){
                cloningConfigsCache.put(parent, cloningConfigs);
            }
        }
        return cloningConfigs;
    }

    private static List<String> fieldsIgnoredWhileCloning(String sObjectAPIName){
        List<String> fieldAPINames = new List<String>();
        fieldAPINames.add('lastModifiedById');
        fieldAPINames.add('createdById');
        fieldAPINames.add('ownerId');
        fieldAPINames.add('status__c');

        return fieldAPINames;
    }

    public static List<String> getAllFieldsAPIName(String sObjectAPIName, List<String> fieldsTobeIgnored){
        Schema.DescribeSObjectResult r = Schema.getGlobalDescribe().get(sObjectAPIName).getDescribe();
        List<String> fieldsAPINames =  new List<String>();

        for(String apiName : r.fields.getMap().keySet()){
            DescribeFieldResult describeFieldResult = r.fields.getMap().get(apiName).getDescribe();
            if (describeFieldResult.isAccessible() && (fieldsTobeIgnored == null ||(fieldsTobeIgnored.size()> 0 && !fieldsTobeIgnored.contains(apiName)))) {
                fieldsAPINames.add(apiName);
            }
        }
        return fieldsAPINames;
    }

    public static List<SObject> getSObjectData(String sObjectAPIName, List<String> fieldAPIName, String whereCondition){
        String soqlFormat = 'SELECT {0} FROM {1}';
        String concatFieldName = String.join(fieldAPIName, ',');
        String soql = String.format(soqlFormat, new List<String> {concatFieldName, sObjectAPIName});

        if(!String.isBlank(whereCondition)){
            soql += whereCondition;
        }

        List<SObject> data = Database.query(soql);
        return data;
    }

    public static SObject cloneObject(SObject objectTobeCloned){
        SObject clonedObject = objectTobeCloned.clone(false,true,false, false);
        return clonedObject;
    }

    public static String getSObjectAPINameFromId(Id recordId){
        return (recordId).getSobjectType().getDescribe().getName();
    }
}