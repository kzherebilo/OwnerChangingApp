({
    parseObjectOptionList : function(objectOptionList) {
        let delimiter = objectOptionList[0];
        let parsedObjectList = [];
        for(let i=1; i < objectOptionList.length; i++) {
            let objectOption = objectOptionList[i].split(delimiter);
            parsedObjectList.push({
                value: objectOption[0], label: objectOption[1]
            });
        }
        return parsedObjectList;
    }
})
