module profan.ecs;

import std.stdio;
import std.algorithm;
import std.traits : PointerTarget;
import std.typecons : Tuple;
import std.conv : to;

alias EntityID = ulong;
alias ComponentType = string;
alias SystemType = int;

enum dependency = 0;

mixin template SystemContainer(Args) {
	private ComponentSystem!Args[] name;
}

class EntityManager {

	private EntityID current_id = 0;
	private IComponentManager[] cms;

	void add_system(S)(IComponentManager cm) {

		cm.set_manager(this);
		cms ~= cm;
		sort(cms);

	}

	EntityID create_entity() {

		return current_id++;

	}

	IComponentManager get_manager(C)(ComponentType system = typeid(C).stringof) {

		return find!("a.name == b")(cms, system)[0];

	}

	C* get_component(C)(EntityID entity) {

		return cast(C*)get_manager!C().component(entity);

	}

	C[EntityID] get_all_components(C)() {

		return cast(C[EntityID])get_manager!C().all_components();

	}

	void unregister_component(C)(EntityID entity, ComponentType system = typeid(C).stringof) {

		if (system == "*") {
			
			foreach(sys; cms) {
				sys.unregister(entity);
			}

			return;

		}

		get_manager!void(system).unregister(entity);

	}

	bool register_component(C)(EntityID entity) {

		try {
			return get_manager!C().register(entity);
		} catch {
			return false;
		}

	}
	
	bool register_component(C)(EntityID entity, C component) {

		try {
			return get_manager!C().register(entity, (cast(void[C.sizeof])component));
		} catch {
			return false;
		}

	}

	void tick(T, Args...)(Args args) {

		foreach (sys; cms) {
			T s = cast(T)sys; //this is slightly evil
			s.update(args);
		}

	}

} //EntityManager

interface IComponentManager {

	bool opEquals(ref const IComponentManager other);
	int opCmp(ref const IComponentManager other);
	void set_manager(EntityManager em);

	@property int priority() const;
	@property ComponentType name() const;
	bool register(EntityID entity);
	bool register(EntityID entity, void[] component);
	void unregister(EntityID entity);
	void* component(EntityID entity);
	void* all_components();

} //IComponentManager

interface ComponentSystem(Args...) : IComponentManager {

	void update(Args...)(Args args);

}

abstract class ComponentManager(System, T, int P = int.max) : System {

	protected {
		EntityManager em;
		T[EntityID] components;
	}

	private static immutable {
		int prio = P;
		ComponentType cname = typeid(T).stringof;
	}

	@property int priority() const { return prio; }
	@property ComponentType name() const { return cname; }

	bool opEquals(ref const IComponentManager other) {

		return name == other.name;

	}
	
	int opCmp(ref const IComponentManager other) {

		if (priority > other.priority) return 1;
		if (priority == other.priority) return 0;
		return -1;

	}
	
	void set_manager(EntityManager em) {

		this.em = em;

	}

	bool register(EntityID entity) {

		components[entity] = construct_component(entity);
		init(&components[entity]);
		return true;

	}

	bool register(EntityID entity, void[] component) {

		components[entity] = *(cast(T*)component);
		return true;

	}

	void unregister(EntityID entity) {

		components.remove(entity);

	}

	void* component(EntityID entity) {

		return &components[entity];

	}

	void* all_components() {

		return &components;

	}

	static template is_dependency(alias attr) {

		enum is_dependency = is(typeof(attr) == typeof(dependency));

	}

	static template has_attribute(list ...) {	

		static if (list.length > 0 && is_dependency!(list[0])) {
			
			enum has_attribute = true;

		} else static if (list.length > 0) {
			
			enum has_attribute = has_attribute!(list[1 .. $]);

		} else {
		
			enum has_attribute = false;

		}

	}

	static template link_dependencies(T, alias comp, alias entsym, list...) {

		static if (list.length > 0 && has_attribute!(__traits(getAttributes, __traits(getMember, T, list[0])))) {

			enum link_dependencies =
				__traits(identifier, comp) ~ "." ~ list[0] ~ " = em.get_component!"
				~ __traits(identifier, PointerTarget!(typeof(__traits(getMember, T, list[0]))))
				~ "("~__traits(identifier, entsym)~");" ~ link_dependencies!(T, comp, entsym, list[1 .. $]);
			
		} else static if (list.length > 0 ) {

			enum link_dependencies = link_dependencies!(T, comp, entsym, list[1 .. $]);

		} else {

			enum link_dependencies = "";

		}

	}

	template fetch_dependencies(T, alias comp, alias entsym) {

		enum fetch_dependencies = link_dependencies!(T, comp, entsym, __traits(allMembers, T));

	}

	T construct_component(EntityID entity) {

		import std.string : format;
		import std.traits : moduleName;

		T c = T();
		mixin fetch_dependencies!(T, c, entity);
		mixin(format("import %s;", moduleName!T));
		mixin(fetch_dependencies);
		return c;
	
	}

	void init(T* component) {
		
	}

} //ComponentManager

version(unittest) {

	interface UpdateSystem : ComponentSystem!() {
		void update();
	}

	struct SomeComponent {
		int value;
	}

	class SomeManager : ComponentManager!(UpdateSystem, SomeComponent, 1) {

		void update() {
			foreach (ref comp; components) {
				comp.value += 1;
			}
		}

	}

	struct OtherComponent {
		@dependency SomeComponent* sc;
	}

	class OtherManager : ComponentManager!(UpdateSystem, OtherComponent, 2) {

		void update(){
			foreach (ref comp; components) {
				if (comp.sc.value == 1) { 
					comp.sc.value += 1;
				}
			}
		}

	}

}

version(unittest) {

	void create_prerequisites(ref EntityManager em, ref EntityID entity) {

		//create manager, system
		em = new EntityManager();
		em.add_system!SomeManager(new SomeManager());
		em.add_system!OtherManager(new OtherManager());

		//create entity and component, add to system
		entity = em.create_entity();
		em.register_component!SomeComponent(entity);
		em.register_component!OtherComponent(entity);

	}

	mixin template PreReq() {

		EntityID entity;
		EntityManager em;

	}

}

unittest {

	mixin PreReq;
	create_prerequisites(em, entity);
	assert(em.get_component!SomeComponent(entity) != null);
	em.get_component!SomeComponent(entity).value = 0;

	em.tick!(UpdateSystem)(); //one iteration, value should now be 2
	auto val = em.get_component!SomeComponent(entity).value;
	assert(val == 2, "expected val of SomeComponent to be 2, order of updating is incorrect, was " ~ to!string(val));

}

unittest {

	import std.exception : assertNotThrown;

	mixin PreReq;
	create_prerequisites(em, entity);
	assertNotThrown!Exception(em.unregister_component!void(entity, "*"), "unregister_component should not throw an exception, likely out of bounds.");

}
