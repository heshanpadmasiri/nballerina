public type Member record {|
    string name;
    SemType valueTy;
    "field"|"method" kind;
|};

SemType MEMBER_KIND_FIELD = stringConst("field");
SemType MEMBER_KIND_METHOD = stringConst("method");

public class ObjectDefinition {
    *Definition;
    private MappingDefinition mappingDefn = new();

    public function getSemType(Env env) returns SemType {
        return objectContaining(self.mappingDefn.getSemType(env));
    }

    public function define(Env env, Member[] members) returns SemType {
        if members.length() == 0 {
            return OBJECT;
        }
        CellField[] fieldCells = from Member member in members where member.kind == "field" select fieldMember(env, member);
        CellField[] methodCells = from Member member in members where member.kind == "method" select methodMember(env, member);
        SemType mappingType = self.mappingDefn.define(env, [...fieldCells, ...methodCells],
                                                      restMemberType(env));
        return objectContaining(mappingType);
    }

}

public function objectContaining(SemType mappingType) returns SemType {
    Bdd bdd = <Bdd>subtypeData(mappingType, BT_MAPPING);
    return createBasicSemType(BT_OBJECT, bdd);
}

function restMemberType(Env env) returns CellSemType {
    SemType fieldMemberType = defineMappingTypeWrapped(new, env, [{ name: "value", ty: ANY },
                                                                  { name: "kind", ty: MEMBER_KIND_FIELD }],
                                                       NEVER);
    SemType methodMemberType = defineMappingTypeWrapped(new, env, [{ name: "value", ty: FUNCTION, ro: true },
                                                                   { name: "kind", ty: MEMBER_KIND_METHOD }],
                                                        NEVER);
    return cellContaining(env, union(fieldMemberType, methodMemberType));
}

function fieldMember(Env env, Member member) returns CellField {
    return { name: member.name,
             ty: cellContaining(env, defineMappingTypeWrapped(new, env, [{ name: "value", ty: member.valueTy },
                                                                         { name: "kind", ty: MEMBER_KIND_FIELD }],
                                                              NEVER)) };
}

function methodMember(Env env, Member member) returns CellField {
    return { name: member.name,
             ty: cellContaining(env, defineMappingTypeWrapped(new, env, [{ name: "value", ty: member.valueTy, ro: true },
                                                                         { name: "kind", ty: MEMBER_KIND_METHOD }],
                                                              NEVER)) };
}

final BasicTypeOps objectOps = {
    union: bddSubtypeUnion,
    intersect: bddSubtypeIntersect,
    diff: bddSubtypeDiff,
    complement: bddSubtypeComplement,
    isEmpty: mappingSubtypeIsEmpty
};
