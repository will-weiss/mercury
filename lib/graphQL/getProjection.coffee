getProjection = (fieldASTs) ->
  fieldASTs.selectionSet.selections.reduce (projections, selection) ->
    projections[selection.name.value] = 1
    projections
  , {
    _id: 1
    vendorId: 1
    brokerId: 1
    employerId: 1
    productId: 1
    employerProductId: 1
    familyId: 1
    groupId: 1
    familyAvailableId: 1
    familyEnrollmentId: 1
  }

module.exports = getProjection
