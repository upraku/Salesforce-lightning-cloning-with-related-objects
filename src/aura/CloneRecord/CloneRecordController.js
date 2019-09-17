({
    init:function(component, event, helper){
        var recID = component.get("v.originalRecordId");
        var action = component.get("c.isCloningPossible");
        action.setParams({ recordId : recID });

        action.setCallback(this, function(response){
            if(response.getReturnValue()){
                helper.cloneRecord(component);
                    }else{
                helper.showError(component, "You cannot clone this record.");
            }
        });
        $A.enqueueAction(action);
        setTimeout(()=>{
                   let quickActionClose = $A.get("e.force:closeQuickAction");
                   quickActionClose.fire();
                },1000);
    }
})