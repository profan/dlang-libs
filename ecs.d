module profan.ecs;

import std.stdio;
import std.algorithm;
import std.traits : PointerTarget;

alias EntityID = ulong;
alias ComponentType = string;

enum dependency = 0;

class EntityManager {

	private EntityID current_id = 0;
	private IComponentManager[] cms;

	void add_system(IComponentManager cm) {

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

	void update_systems() {

		foreach (sys; cms) {
			sys.update();
		}

	}

} //EntityManager

interface IComponentManager {

	bool opEquals(ref const IComponentManager other);
	int opCmp(ref const IComponentManager other);
	void set_manager(EntityManager em);

	@property int priority() const;
	@property string name() const;
	bool register(EntityID entity);
	bool register(EntityID entity, void[] component);
	void unregister(EntityID entity);
	void* component(EntityID entity);
	void* all_components();

	void update();

} //IComponentManager

class ComponentManager(T, int P = int.max) : IComponentManager {

	protected EntityManager em;
	static immutable int prio = P;
	protected T[EntityID] components;
	private static immutable ComponentType cname = typeid(T).stringof;

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

	/*template link_dependencies(T, alias comp, alias entsym) {

		string do_stuff() {
			string str = "";
			foreach (member; __traits(allMembers, T)) {

				auto props = __traits(getAttributes, __traits(getMember, T, member));

				foreach (p; props) {
					static if (is_dependency!p) {
						pragma(msg,
							__traits(identifier, comp) ~ "." ~ member ~ " = em.get_component!"
							~ __traits(identifier, PointerTarget!(typeof(__traits(getMember, T, member))))
							~ "("~__traits(identifier, entsym)~");");
						str ~= __traits(identifier, comp) ~ "." ~ member ~ " = em.get_component!"
							~ __traits(identifier, PointerTarget!(typeof(__traits(getMember, T, member))))
							~ "("~__traits(identifier, entsym)~");";
					}
				}

			}

			return str;
		}

		enum link_dependencies = do_stuff();

	}*/

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

	abstract void update();

} //ComponentManager
