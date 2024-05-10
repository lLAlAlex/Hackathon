import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Project, Reward } from '@/declarations/project_backend/project_backend.did';
import Search from '@/components/ui/search/Search';
import { CheckboxGroup, Pagination } from '@nextui-org/react';
import { project_backend } from '@/declarations/project_backend';
import GridLayout from '@/components/layout/grid/GridLayout';
import ProjectCard from '@/components/cards/projects/ProjectCard';
import { CustomCheckbox } from '@/components/ui/CustomCheckbox';
// export interface Project {
//     'id' : string,
//     'name' : string,
//     'description' : string,
//     'reviews_ids' : Array<string>,
//     'deadline' : bigint,
//     'progress' : bigint,
//     'timestamp' : Time,
//     'category' : string,
//     'image' : string,
//     'company_id' : string,
//   }

// const rewards: Reward[] = [
//   { tier: 'Bronze', price: BigInt(100) },
//   { tier: 'Silver', price: BigInt(200) },
//   { tier: 'Gold', price: BigInt(300) },
// ];

// const dummy: Project[] = [
//   {
//     id: 'asd',
//     name: 'asd',
//     description: 'lorem ipsum asdasdasdad',
//     reviews_ids: [],
//     deadline: "05-04-2025",
//     progress: BigInt(0),
//     goal: BigInt(60000),
//     category: 'ASdasd',
//     user_id: 'asdasd',
//     rewards: rewards,
//     image: 'https://picsum.photos/200/300',
//     timestamp: BigInt(12124124),
//   },
//   {
//     id: 'asd1',
//     name: 'asd',
//     description: 'lorem ipsum asdasdasdad',
//     reviews_ids: [],
//     deadline: "05-04-2025",
//     progress: BigInt(0),
//     goal: BigInt(60000),
//     category: 'ASdasd',
//     user_id: 'asdasd',
//     rewards: rewards,
//     image: 'https://picsum.photos/200/300',
//     timestamp: BigInt(12124124),
//   },
//   {
//     id: 'asd2',
//     name: 'asd',
//     description: 'lorem ipsum asdasdasdad',
//     reviews_ids: [],
//     deadline: "05-04-2025",
//     progress: BigInt(0),
//     goal: BigInt(60000),
//     category: 'ASdasd',
//     user_id: 'asdasd',
//     rewards: rewards,
//     image: 'https://picsum.photos/300/300',
//     timestamp: BigInt(12124124),
//   },
//   {
//     id: 'asd3',
//     name: 'asd',
//     description: 'lorem ipsum asdasdasdad',
//     reviews_ids: [],
//     deadline: "05-04-2025",
//     progress: BigInt(0),
//     goal: BigInt(60000),
//     category: 'ASdasd',
//     user_id: 'asdasd',
//     rewards: rewards,
//     image: 'https://picsum.photos/400/300',
//     timestamp: BigInt(12124124),
//   },
// ];

function ProjectPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState<string>('');
  const [page, setPage] = useState(1);
  const [totalPage, setTotalPage] = useState(10);
  const [projects, setProjects] = useState<Project[]>([]);
  const [groupSelected, setGroupSelected] = useState<string[]>([]);
  async function fetchProjects(search: string, page: number) {
    try {
      setProjects([]);
      const result = await project_backend.getAllProjects([search], BigInt(page));
      if ('ok' in result) {
        if (result.ok.length != 0) {
          setProjects(result.ok);
        }
      } else {
        console.error('Error fetching projects:', result.err);
      }
    } catch (error) {
      console.log(error)
      // console.error('Error fetching projects:', error);
    }
  }
  const handleSearch = () => {
    // do something with search
    fetchProjects(search, page)
  };

  useEffect(() => {
    if (page > 0) {
      fetchProjects("", page);
    }
  }, [page]);

  useEffect(() => {
    const fetchTotalPages = async () => {
      const res = await project_backend.getTotalProjectCount();
      setTotalPage(Math.ceil(Number(res) / 20))
    }

    fetchTotalPages()
  }, [])


  return (
    <>
      <div className="w-full mb-5 mt-12">
        <div className="max-w-[1200px] w-9/12 mx-auto">
          <Search
            value={search}
            handleChange={(v) => setSearch(v)}
            onSubmit={handleSearch}
          />
          <div className="flex flex-col my-3 w-full">
            <CheckboxGroup
              className="gap-1"
              orientation="horizontal"
              value={groupSelected}
              onChange={(value: string[]) => setGroupSelected(value)}
            >
              <CustomCheckbox value="Development & IT">Development & IT</CustomCheckbox>
              <CustomCheckbox value="AI Service">AI Service</CustomCheckbox>
              <CustomCheckbox value="Design & Creative">Design & Creative</CustomCheckbox>
              <CustomCheckbox value="Sales & Marketing">Sales & Marketing</CustomCheckbox>
              <CustomCheckbox value="Finance & Accounting">Finance & Accounting</CustomCheckbox>
              <CustomCheckbox value="Food & Beverages">Food & Beverages</CustomCheckbox>
            </CheckboxGroup>
          </div>
        </div>
      </div>
      <div className='flex flex-col items-center w-full'>
        <GridLayout>
          {projects.map((p, idx) => (
            <ProjectCard project={p} key={idx} />
          ))}
        </GridLayout>
        <div className="py-4 w-full flex justify-center">
          <Pagination
            total={totalPage}
            initialPage={1}
            color="secondary"
            page={page}
            onChange={(n) => setPage(n)}
          />
        </div>
      </div>
    </>
  );
}

export default ProjectPage;
