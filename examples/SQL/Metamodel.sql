CREATE TABLE AllowedRange (
	ValueRestrictionId	int NOT NULL,
	ValueRangeMinimumBoundValue	varchar(256) NULL,
	ValueRangeMinimumBoundIsInclusive	bit NULL,
	ValueRangeMaximumBoundValue	varchar(256) NULL,
	ValueRangeMaximumBoundIsInclusive	bit NULL,
	UNIQUE(ValueRestrictionId, ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	ConstraintId	int NOT NULL,
	Enforcement	varchar(16) NULL,
	Name	varchar(64) NULL,
	PresenceConstraintIsMandatory	bit NULL,
	PresenceConstraintIsPreferredIdentifier	bit NULL,
	PresenceConstraintMaxFrequency	int NULL,
	PresenceConstraintMinFrequency	int NULL,
	PresenceConstraintRoleSequenceId	int NULL,
	RingConstraintOtherRoleConceptName	varchar(64) NULL,
	RingConstraintOtherRoleConceptVocabularyName	varchar(64) NULL,
	RingConstraintOtherRoleFactTypeId	int NULL,
	RingConstraintOtherRoleOrdinal	UnsignedSmallInteger(32) NULL,
	RingConstraintRingType	varchar NULL,
	RingConstraintRoleConceptName	varchar(64) NULL,
	RingConstraintRoleConceptVocabularyName	varchar(64) NULL,
	RingConstraintRoleFactTypeId	int NULL,
	RingConstraintRoleOrdinal	UnsignedSmallInteger(32) NULL,
	SetExclusionConstraintIsMandatory	bit NULL,
	SubsetConstraintSubsetRoleSequenceId	int NULL,
	SubsetConstraintSupersetRoleSequenceId	int NULL,
	VocabularyName	varchar(64) NULL,
	PRIMARY KEY(ConstraintId)
)
GO

CREATE TABLE Correspondence (
	ImportVocabularyName	varchar(64) NOT NULL,
	ImportImportedVocabularyName	varchar(64) NOT NULL,
	ImportedFeatureName	varchar(64) NOT NULL,
	ImportedFeatureVocabularyName	varchar(64) NULL,
	LocalFeatureName	varchar(64) NOT NULL,
	LocalFeatureVocabularyName	varchar(64) NULL,
	UNIQUE(ImportVocabularyName, ImportImportedVocabularyName, ImportedFeatureName, ImportedFeatureVocabularyName)
)
GO

CREATE TABLE Derivation (
	DerivedUnitId	int NOT NULL,
	BaseUnitId	int NOT NULL,
	Exponent	SignedSmallInteger(32) NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	FactId	int NOT NULL,
	FactTypeId	int NOT NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	FactTypeId	int NOT NULL,
	EntityTypeName	varchar(64) NULL,
	EntityTypeVocabularyName	varchar(64) NULL,
	TypeInheritanceProvidesIdentification	bit NULL,
	TypeInheritanceSubtypeName	varchar(64) NULL,
	TypeInheritanceSubtypeVocabularyName	varchar(64) NULL,
	TypeInheritanceSupertypeName	varchar(64) NULL,
	TypeInheritanceSupertypeVocabularyName	varchar(64) NULL,
	PRIMARY KEY(FactTypeId)
)
GO

CREATE TABLE Feature (
	Name	varchar(64) NOT NULL,
	VocabularyName	varchar(64) NULL,
	ConceptIsIndependent	bit NULL,
	ConceptIsPersonal	bit NULL,
	EntityTypeFactTypeId	int NULL,
	ValueTypeLength	int NULL,
	ValueTypeScale	int NULL,
	ValueTypeSupertypeName	varchar(64) NULL,
	ValueTypeSupertypeVocabularyName	varchar(64) NULL,
	ValueTypeUnitId	int NULL,
	ValueTypeValueRestrictionId	int NULL,
	UNIQUE(Name, VocabularyName)
)
GO

CREATE TABLE Instance (
	InstanceId	int NOT NULL,
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	Value	varchar(256) NULL,
	PRIMARY KEY(InstanceId)
)
GO

CREATE TABLE JoinPath (
	RoleRefRoleSequenceId	int NOT NULL,
	RoleRefOrdinal	UnsignedSmallInteger(32) NOT NULL,
	JoinStep	UnsignedSmallInteger(32) NOT NULL,
	ConceptName	varchar(64) NULL,
	ConceptVocabularyName	varchar(64) NULL,
	InputRoleConceptName	varchar(64) NOT NULL,
	InputRoleConceptVocabularyName	varchar(64) NULL,
	InputRoleFactTypeId	int NOT NULL,
	InputRoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	OutputRoleConceptName	varchar(64) NOT NULL,
	OutputRoleConceptVocabularyName	varchar(64) NULL,
	OutputRoleFactTypeId	int NOT NULL,
	OutputRoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

CREATE TABLE Reading (
	FactTypeId	int NOT NULL,
	Ordinal	UnsignedSmallInteger(32) NOT NULL,
	RoleSequenceId	int NOT NULL,
	Text	varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY(FactTypeId)
	REFERENCES FactType(FactTypeId)
)
GO

CREATE TABLE Role (
	FactTypeId	int NOT NULL,
	Ordinal	UnsignedSmallInteger(32) NOT NULL,
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	RoleName	varchar(64) NULL,
	RoleValueRestrictionId	int NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName),
	FOREIGN KEY(FactTypeId)
	REFERENCES FactType(FactTypeId)
)
GO

CREATE TABLE RoleRef (
	RoleSequenceId	int NOT NULL,
	Ordinal	UnsignedSmallInteger(32) NOT NULL,
	LeadingAdjective	varchar(64) NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	TrailingAdjective	varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	FOREIGN KEY(RoleFactTypeId, RoleOrdinal, RoleConceptName, RoleConceptVocabularyName)
	REFERENCES Role(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceId	int NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	InstanceId	int NOT NULL,
	FactId	int NOT NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY(FactId)
	REFERENCES Fact(FactId),
	FOREIGN KEY(InstanceId)
	REFERENCES Instance(InstanceId),
	FOREIGN KEY(RoleFactTypeId, RoleOrdinal, RoleConceptName, RoleConceptVocabularyName)
	REFERENCES Role(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE SetComparisonRoles (
	SetComparisonConstraintId	int NOT NULL,
	RoleSequenceId	int NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY(RoleSequenceId)
	REFERENCES RoleSequence(RoleSequenceId)
)
GO

CREATE TABLE Unit (
	UnitId	int NOT NULL,
	CoefficientDenominator	int NULL,
	CoefficientIsPrecise	bit NULL,
	CoefficientNumerator	decimal NULL,
	IsFundamental	bit NOT NULL,
	Name	varchar(64) NOT NULL,
	PRIMARY KEY(UnitId)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionId	int NOT NULL,
	PRIMARY KEY(ValueRestrictionId)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY(ValueRestrictionId)
	REFERENCES ValueRestriction(ValueRestrictionId)
GO

ALTER TABLE Correspondence
	ADD FOREIGN KEY(ImportedFeatureName, ImportedFeatureVocabularyName)
	REFERENCES Feature(Name, VocabularyName)
GO

ALTER TABLE Correspondence
	ADD FOREIGN KEY(LocalFeatureName, LocalFeatureVocabularyName)
	REFERENCES Feature(Name, VocabularyName)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY(BaseUnitId)
	REFERENCES Unit(UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY(DerivedUnitId)
	REFERENCES Unit(UnitId)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY(FactTypeId)
	REFERENCES FactType(FactTypeId)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY(EntityTypeName, EntityTypeVocabularyName)
	REFERENCES EntityType(ConceptName, ConceptVocabularyName)
GO

ALTER TABLE Instance
	ADD FOREIGN KEY(ConceptName, ConceptVocabularyName)
	REFERENCES Concept(FeatureName, FeatureVocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY(ConceptName, ConceptVocabularyName)
	REFERENCES Concept(FeatureName, FeatureVocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY(InputRoleFactTypeId, InputRoleOrdinal, InputRoleConceptName, InputRoleConceptVocabularyName)
	REFERENCES Role(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY(OutputRoleFactTypeId, OutputRoleOrdinal, OutputRoleConceptName, OutputRoleConceptVocabularyName)
	REFERENCES Role(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY(RoleRefRoleSequenceId, RoleRefOrdinal)
	REFERENCES RoleRef(RoleSequenceId, Ordinal)
GO

ALTER TABLE Reading
	ADD FOREIGN KEY(RoleSequenceId)
	REFERENCES RoleSequence(RoleSequenceId)
GO

ALTER TABLE Role
	ADD FOREIGN KEY(ConceptName, ConceptVocabularyName)
	REFERENCES Concept(FeatureName, FeatureVocabularyName)
GO

ALTER TABLE Role
	ADD FOREIGN KEY(RoleValueRestrictionId)
	REFERENCES ValueRestriction(ValueRestrictionId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY(RoleSequenceId)
	REFERENCES RoleSequence(RoleSequenceId)
GO

ALTER TABLE SetComparisonRoles
	ADD FOREIGN KEY(SetComparisonConstraintId)
	REFERENCES SetComparisonConstraint(SetConstraintId)
GO

